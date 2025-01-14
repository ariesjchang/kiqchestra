# frozen_string_literal: true

require "sidekiq"

module Sidekhestra
  class JobWorker
    include Sidekiq::Worker

    def perform
      puts "Performing job in #{self.class.name}"
      # Simulate job logic here
    end
  end
end
