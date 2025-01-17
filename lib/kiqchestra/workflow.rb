# frozen_string_literal: true

require "sidekiq"
require "redis"

module Kiqchestra
  # The Workflow class provides functionality for orchestrating
  # Sidekiq-based job workflows. It manages task dependencies
  # and tracks their completion status.
  class Workflow
    # Initializes the workflow with dependencies and optional logger.
    #
    # @param workflow_id [String] Unique ID for the workflow
    # @param dependencies [Hash] A hash defining job dependencies (e.g., { job_a: [], job_b: [:job_a] })
    def initialize(workflow_id, dependencies)
      @workflow_id = workflow_id
      @dependencies = dependencies
      @logger = Logger.new($stdout)

      validate_dependencies
      save_dependencies dependencies
    end

    # Starts the workflow execution.
    def execute
      progress = read_progress
      @dependencies.each do |job, job_data|
        process_job job, job_data, progress
      end

      conclude_workflow if workflow_complete?
    end

    # Handles the completion of a job and triggers the next jobs if dependencies are met.
    #
    # @param job [String] The completed job name (ex. "example_job")
    def handle_completed_job(job)
      update_progress job, "complete"
      log_info "#{job} completed for workflow #{@workflow_id}"

      execute
    end

    private

    # Validates the dependencies structure for a workflow.
    # Ensures that all job metadata, dependencies, and arguments conform to the expected format.
    def validate_dependencies
      # Ensure the root structure is a hash
      raise ArgumentError, "Dependencies must be a hash" unless @dependencies.is_a?(Hash)

      # Validate each job's metadata
      @dependencies.each do |job, data|
        validate_metadata job, data
      end
    end

    # Validates the metadata for a specific job.
    # Ensures that the metadata is a hash and its components (deps and args) are correctly structured.
    #
    # @param job [Symbol, String] The job identifier
    # @param data [Hash] Metadata for the job (includes deps and args)
    def validate_metadata(job, data)
      # Check if the metadata is a hash
      raise ArgumentError, "Metadata for #{job} must be a hash" unless data.is_a?(Hash)

      # Validate dependencies and arguments separately
      validate_deps job, data[:deps]
      validate_args job, data[:args]
    end

    # Validates the dependencies (`deps`) for a specific job.
    # Ensures that dependencies are an array of symbols or strings.
    #
    # @param job [Symbol, String] The job identifier
    # @param deps [Array<Symbol, String>] Dependencies for the job
    def validate_deps(job, deps)
      return if deps.is_a?(Array) && deps.all? { |dep| dep.is_a?(String) || dep.is_a?(Symbol) }

      raise ArgumentError, "Dependencies for #{job} must be an array of strings or symbols"
    end

    # Validates the arguments (`args`) for a specific job.
    # Ensures that arguments are either an array or nil.
    #
    # @param job [Symbol, String] The job identifier
    # @param args [Array, nil] Arguments for the job
    def validate_args(job, args)
      return if args.nil? || args.is_a?(Array)

      raise ArgumentError, "Arguments for #{job} must be an array or nil"
    end

    # Returns the Redis key for storing workflow dependencies.
    def workflow_dependencies_key
      "workflow:#{@workflow_id}:dependencies"
    end

    # Returns the Redis key for storing workflow progress.
    def workflow_progress_key
      "workflow:#{@workflow_id}:progress"
    end

    # Saves the task dependencies using the configured dependencies store.
    #
    # @param [Hash] dependencies A hash where keys are task names and values are arrays of dependencies.
    # @example save_dependencies(job1: [:job2, :job3], job2: [])
    def save_dependencies(dependencies)
      Kiqchestra.config.store.write_dependencies @workflow_id, dependencies
    end

    # Processes a single job during workflow execution.
    #
    # @param job [String] The job identifier
    # @param job_data [Hash] Metadata for the job (dependencies and arguments)
    # @param progress [Hash] The current workflow progress
    def process_job(job, job_data, progress)
      return if job_already_processed? job, progress

      return unless ready_to_execute? job_data[:deps], progress

      args = job_data[:args] || []
      enqueue_job job, args
    end

    # Checks if a job is already processed (completed or in_progress).
    #
    # @param job [String] The job identifier
    # @param progress [Hash] The current workflow progress
    # @return [Boolean] True if the job is completed or in progress
    def job_already_processed?(job, progress)
      %w[complete in_progress].include? progress[job.to_s]
    end

    # Checks if a job is ready for execution (no dependencies or all dependencies completed).
    #
    # @param deps [Array<Symbol, String>] Dependencies for the job
    # @param progress [Hash] The current workflow progress
    # @return [Boolean] True if the job is ready to execute
    def ready_to_execute?(deps, progress)
      deps.empty? || deps.all? { |dep| progress[dep.to_s] == "complete" }
    end

    # Enqueues a Sidekiq job for execution and saves the job's status as "in_progress".
    #
    # @param job [String] Job name in snake_case.
    # @param args [Array] Arguments to pass to the job's perform method (default: empty array).
    def enqueue_job(job, args = [])
      job_class_name = job.to_s.split("_").map(&:capitalize).join
      job_class = Object.const_get(job_class_name)
      job_class.perform_async @workflow_id, *args
      update_progress job, "in_progress"
    rescue NameError
      raise "Class for job '#{job}' not defined"
    end

    # Logs a message if a logger is configured.
    def log_info(message)
      @logger&.info "kiqchestra: #{message}"
    end

    # Updates the workflow progress for a job.
    #
    # @param job [String] job name in snake_case
    # @param status [String] job status ("in_progress", "completed")
    def update_progress(job, status)
      progress = read_progress
      progress[job] = status
      Kiqchestra.config.store.write_progress @workflow_id, progress
    end

    # Reads the current workflow progress from Redis.
    #
    # @return [Hash] The current progress of the workflow
    def read_progress
      Kiqchestra.config.store.read_progress @workflow_id
    end

    # Checks if the workflow is complete (all jobs are completed) and logs the workflow's end.
    def workflow_complete?
      progress = read_progress
      @dependencies.keys.all? { |job| progress[job.to_s] == "complete" }
    end

    # Executes the customizable on-complete procedure for the workflow.
    def conclude_workflow
      log_info "Workflow #{@workflow_id} has completed successfully."
    end
  end
end
