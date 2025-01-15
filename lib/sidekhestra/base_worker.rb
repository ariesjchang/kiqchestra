# frozen_string_literal: true

require "sidekiq"

module Sidekhestra
  # BaseWorker provides a standard interface for all workflow jobs.
  # It includes the necessary callback mechanism to notify the Workflow
  # once a job has completed and trigger any follow-up jobs based on the dependencies.
  #
  # Subclasses are expected to implement the `perform` method to define
  # the specific logic for the job. This method will be automatically
  # invoked as part of the job execution flow, and callbacks like `on_complete`
  # will be triggered when the job finishes.
  class BaseWorker
    include Sidekiq::Worker

    # Perform the job and trigger workflow callbacks on completion.
    #
    # @param workflow_id [String] The unique ID for the workflow
    # @param args [Array] Arguments to be passed to the specific job's perform method
    def perform(workflow_id, *args)
      @workflow_id = workflow_id
      @args = args

      log_info "Starting job in workflow #{@workflow_id}: #{self.class.name}"

      begin
        # Delegate the actual job work to the subclass's perform method
        perform_job(*@args)

        # Call on_complete callback when the job is finished
        on_complete
      rescue StandardError => e
        log_error "Job #{job_name} failed: #{e.message}"

        # Re-raise to let Sidekiq handle retries
        raise e
      end
    end

    # Subclasses should define the actual job logic here.
    # This is called by the `perform` method of BaseWorker.
    #
    # @param args [Array] Arguments passed to the job
    def perform_job(*args)
      raise NotImplementedError, "Subclasses must implement `perform_job`"
    end

    private

    # Callback method invoked when the job completes.
    # It updates job progress and triggers the next jobs.
    def on_complete
      workflow.job_completed job_name
      log_info "Job #{job_name} completed for workflow #{@workflow_id}"
    end

    # Fetch the workflow instance
    def workflow
      @workflow ||= Workflow.new @workflow_id, fetch_dependencies
    end

    # Extract job name from the class
    def job_name
      self.class.name.demodulize.underscore.to_sym
    end

    # Fetch the job's dependencies from the cache
    def fetch_dependencies
      JSON.parse(Rails.cache.read(workflow.workflow_dependencies_key) || "{}")
    end

    # Logs an info-level message
    def log_info(message)
      Sidekiq.logger.info message
    end

    # Logs an error-level message
    def log_error(message)
      Sidekiq.logger.error message
    end
  end
end
