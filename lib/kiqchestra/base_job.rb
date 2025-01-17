# frozen_string_literal: true

require "sidekiq"
require "kiqchestra/workflow"

module Kiqchestra
  # BaseJob provides a standard interface for all workflow jobs.
  # It includes the necessary callback mechanism to notify the Workflow
  # once a job has completed and trigger any follow-up jobs based on the dependencies.
  #
  # Subclasses are expected to implement the `perform` method to define
  # the specific logic for the job. This method will be automatically
  # invoked as part of the job execution flow, and callbacks like `on_complete`
  # will be triggered when the job finishes.
  class BaseJob
    include Sidekiq::Worker

    # Perform the job and trigger workflow callbacks on completion.
    #
    # @param workflow_id [String] The unique ID for the workflow
    # @param args [Array] Arguments to be passed to the specific job's perform method
    def perform(workflow_id, *args)
      @workflow_id = workflow_id
      @args = args

      log_info "Starting job #{job_name} in workflow #{@workflow_id} with args: #{@args.inspect}"

      begin
        # Delegate the actual job work to the subclass's perform method
        perform_job *@args

        workflow.handle_completed_job job_name
      rescue StandardError => e
        log_error "#{job_name} failed: #{e.message}"

        # Re-raise to let Sidekiq handle retries
        raise e
      end
    end

    # Subclasses should define the actual job logic here.
    # This is called by the `perform` method of BaseJob.
    #
    # @param args [Array] Arguments passed to the job
    def perform_job(*args)
      raise NotImplementedError, "Subclasses must implement `perform_job`"
    end

    private

    # Fetch the workflow instance lazily, using pre-fetched workflow data.
    def workflow
      @workflow ||= Workflow.new @workflow_id, metadata
    end

    # Extract job name from the class
    # .split('::').last : equivalent to Rails's demodulize
    def job_name
      self.class.name.split("::").last.underscore
    end

    # Same as Rails's underscore
    def underscore
      self.gsub(/::/, '/').
      gsub(/([A-Z]+)([A-Z][a-z])/,'\1_\2').
      gsub(/([a-z\d])([A-Z])/,'\1_\2').
      tr("-", "_").
      downcase
    end

    # Fetch the cached workflow data from redis
    def metadata
      return @metadata if @metadata&.present?

      metadata = Kiqchestra.config.store.read_metadata @workflow_id
      @metadata = metadata.transform_keys(&:to_sym).transform_values do |data|
        { deps: data["deps"].map(&:to_sym), args: data["args"] }
      end
    end

    # Logs an info-level message
    def log_info(message)
      Sidekiq.logger.info "kiqchestra: #{message}"
    end

    # Logs an error-level message
    def log_error(message)
      Sidekiq.logger.error "kiqchestra: #{message}"
    end
  end
end
