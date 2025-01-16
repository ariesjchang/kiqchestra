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
    # @param logger [Logger, nil] Optional logger (defaults to STDOUT). Pass `nil` to disable logging.
    def initialize(workflow_id, dependencies, logger: Logger.new($stdout))
      @workflow_id = workflow_id
      @dependencies = dependencies
      @logger = logger
      @dependencies_store = Kiqchestra.config.dependencies_store
      @progress_store = Kiqchestra.config.progress_store

      validate_dependencies
      save_dependencies dependencies
    end

    # Starts the workflow execution.
    def execute
      log_info "Starting workflow: #{@workflow_id}"
      start_initial_jobs
    end

    # Handles the completion of a job and triggers the next jobs if dependencies are met.
    #
    # @param job [String] The completed job name (ex. "example_job")
    def job_completed(job)
      update_progress job, "completed"
      log_info "#{job} completed for workflow #{@workflow_id}"

      trigger_next_jobs job
      check_workflow_completion
    end

    private

    # Validates the structure of the dependencies hash.
    def validate_dependencies
      log_info 'start validating dependencies'
      raise ArgumentError, "Dependencies must be a hash" unless @dependencies.is_a?(Hash)

      @dependencies.each do |job, deps|
        raise ArgumentError, "Dependencies for #{job} must be an array" unless deps.is_a?(Array)
      end
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
      log_info "saving dependencies: #{dependencies}"
      @dependencies_store.write_dependencies @workflow_id, dependencies
    end

    # Starts jobs without any dependencies.
    def start_initial_jobs
      progress = read_progress
      log_info "progress: #{progress}"
      log_info "@dependencies: #{@dependencies}"
      @dependencies.each do |job, deps|
        # Skip jobs already marked as completed
        log_info "job: #{job} / #{job.class} / progress[job]: #{progress[job]}"
        next if progress[job] == "completed"

        # Run jobs without dependencies and jobs whose dependencies are all completed
        if deps.empty? || deps.all? { |dep| progress[dep] == "completed" }
          log_info "Starting job: #{job} for workflow #{@workflow_id}"
          enqueue_job job
        end
      end
    end

    # Enqueues a Sidekiq job for execution and saves the job's status as "in_progress".
    # 
    # @param job [String] job name in snake_case
    def enqueue_job(job)
      log_info "start enqueue_job #{job}"
      worker_class = Object.const_get "#{job.to_s.camelize}"
      worker_class.perform_async @workflow_id
      update_progress job, "in_progress"
    rescue NameError
      raise "Worker class for job '#{job}' not defined"
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
      log_info "start update_progress #{job}, #{status}"
      progress = read_progress
      progress[job] = status
      log_info "new progress: #{progress}"
      @progress_store.write_progress @workflow_id, progress
    end

    # Reads the current workflow progress from Redis.
    #
    # @return [Hash] The current progress of the workflow
    def read_progress
      @progress_store.read_progress @workflow_id
    end

    # Checks if the workflow is complete (all jobs are completed) and logs the workflow's end.
    def check_workflow_completion
      log_info "checking workflow completion"
      progress = read_progress
      log_info "progress: #{progress}"
      log_info "@dependencies: #{@dependencies}"
      all_completed = @dependencies.keys.all? { |job| progress[job] == "completed" }

      return unless all_completed

      log_info "Workflow #{@workflow_id} has completed successfully."
    end

    # Triggers the next jobs whose dependencies are now satisfied.
    #
    # @param completed_job [String] The job that was just completed
    def trigger_next_jobs(completed_job)
      log_info "start trigger_next_jobs: #{completed_job}"
      progress = read_progress
      log_info "progress: #{progress}"
      log_info "@dependencies: #{@dependencies}"
      @dependencies.each do |job, deps|
        next if progress[job] == "completed" # Skip already completed jobs

        if deps.include?(completed_job) && deps.all? { |dep| progress[dep] == "completed" }
          log_info "All dependencies met. Starting job: #{job}"
          enqueue_job job
        end
      end
    end
  end
end
