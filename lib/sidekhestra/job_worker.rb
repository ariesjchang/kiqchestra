# frozen_string_literal: true

require "sidekiq"

module Sidekhestra
  # Sidekhestra::JobWorker
  #
  # This class represents a worker in the Sidekhestra job orchestration system.
  # It is responsible for executing individual steps in the workflow, managing job
  # execution, and interacting with Sidekiq to process jobs asynchronously.
  #
  # The JobWorker is typically used as part of a larger workflow in which different
  # jobs are chained or have dependencies.
  class JobWorker
    include Sidekiq::Worker

    def perform
      puts "Performing job in #{self.class.name}"
      # Simulate job logic here
    end
  end
end
