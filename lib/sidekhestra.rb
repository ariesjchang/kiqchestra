# frozen_string_literal: true

require_relative "sidekhestra/version"
require "sidekiq"

module Sidekhestra
  class Workflow
    attr_reader :steps, :progress

    # Allow users to configure the logger
    def initialize(logger: Logger.new($stdout))
      @logger = logger
      @steps = []
      @progress = {}
    end

    def add_step(step_name, job_class, dependencies: [])
      @steps << { step_name: step_name, job_class: job_class, dependencies: dependencies }
      @progress[step_name] = :pending
    end

    def execute
      @steps.each do |step|
        if dependencies_completed?(step[:dependencies])
          trigger_job(step[:job_class], step[:step_name])
        else
          puts "Skipping #{step[:step_name]} as dependencies are not completed."
        end
      end
    end

    private

    def dependencies_completed?(dependencies)
      dependencies.all? { |dep| @progress[dep] == :completed }
    end

    def trigger_job(job_class, step_name)
      job_class.perform_async
      @progress[step_name] = :completed
      log_info "#{step_name} executed successfully."
    rescue Sidekiq::Worker::EnqueueError => e
      @progress[step_name] = :failed
      log_error "#{step_name} failed with Sidekiq::Worker::EnqueueError: #{e.message}"
    end

    def log_info(message)
      @logger.info(message)
    end

    def log_error(message)
      @logger.error(message)
    end
  end

  class Error < StandardError; end
  # Your code goes here...
end
