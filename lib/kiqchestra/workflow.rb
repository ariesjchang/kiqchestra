# frozen_string_literal: true

require "sidekiq"
require "redis"

module Kiqchestra
  # The Workflow class provides functionality for orchestrating
  # Sidekiq-based job workflows. It manages task dependencies
  # and tracks their completion status.
  class Workflow
    # Initializes the workflow with workflow id and data.
    #
    # @param workflow_id [String] Unique ID for the workflow
    # @param metadata [Hash] Hash defining jobs' dependencies and arguments
    # @example {
    #   a_job: { deps: [], args: a_job_args },
    #   b_job: { deps: [:a_job], args: b_job_args },
    #   c_job: { deps: [:a_job], args: c_job_args },
    #   d_job: { deps: %i[b_job c_job], args: d_job_args }
    # }
    def initialize(workflow_id, metadata)
      @workflow_id = workflow_id
      @metadata = metadata
      @logger = Logger.new($stdout)

      validate_metadata
      cache_metadata metadata
    end

    # Starts the workflow execution.
    def execute
      read_progress
      @metadata.each do |job, job_data|
        process_job job, job_data
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

    # Validates the workflow data structure for a workflow.
    # Ensures that all job metadata, dependencies, and arguments conform to the expected format.
    def validate_metadata
      # Ensure the root structure is a hash
      raise ArgumentError, "Metadata must be a hash" unless @metadata.is_a?(Hash)

      # Validate each job's metadata
      @metadata.each do |job, data|
        validate_job_metadata job, data
      end
    end

    # Validates the metadata for a specific job.
    # Ensures that the metadata is a hash and its components (deps and args) are correctly structured.
    #
    # @param job [Symbol, String] The job identifier
    # @param data [Hash] Metadata for the job (includes deps and args)
    def validate_job_metadata(job, data)
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

    # Caches the workflow data using the configured workflow store.
    def cache_metadata(metadata)
      Kiqchestra.config.store.write_metadata @workflow_id, metadata
    end

    # Processes a single job during workflow execution.
    #
    # @param job [String] The job identifier
    # @param job_metadata [Hash] Metadata for the job (dependencies and arguments)
    def process_job(job, job_metadata)
      return if job_already_processed? job

      return unless ready_to_execute? job_metadata[:deps]

      args = job_metadata[:args] || []
      enqueue_job job, args
    end

    # Checks if a job is already processed (completed or in_progress).
    #
    # @param job [String] The job identifier
    # @return [Boolean] True if the job is completed or in progress
    def job_already_processed?(job)
      progress = read_progress
      %w[complete in_progress].include? progress[job.to_s]
    end

    # Checks if a job is ready for execution (no dependencies or all dependencies completed).
    #
    # @param deps [Array<Symbol, String>] Dependencies for the job
    # @return [Boolean] True if the job is ready to execute
    def ready_to_execute?(deps)
      progress = read_progress
      deps.empty? || deps.all? { |dep| progress[dep.to_s] == "complete" }
    end

    # Enqueues a Sidekiq job for execution and saves the job's status as "in_progress".
    #
    # @param job [String] Job name in snake_case.
    # @param args [Array] Arguments to pass to the job's perform method (default: empty array).
    def enqueue_job(job, args = [])
      return if job_already_processed? job

      update_progress job, "in_progress"

      job_class_name = job.to_s.split("_").map(&:capitalize).join
      job_class = Object.const_get(job_class_name)
      job_class.perform_async @workflow_id, *args
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
      @metadata.keys.all? { |job| progress[job.to_s] == "complete" }
    end

    # Executes the customizable on-complete procedure for the workflow.
    def conclude_workflow
      log_info "Workflow #{@workflow_id} has completed successfully."
    end
  end
end
