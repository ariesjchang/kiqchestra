# frozen_string_literal: true

require "sidekiq"
require_relative "kiqchestra/version"
require_relative "kiqchestra/workflow"
require_relative "kiqchestra/base_worker"
require_relative "kiqchestra/config"

# Kiqchestra is a Sidekiq-based job orchestration framework designed for
# workflows where tasks depend on the completion of other tasks.
# It simplifies the process of managing complex job dependencies, enabling developers
# to focus on business logic rather than the intricacies of dependency management.
module Kiqchestra
  class << self
    # Yields the configuration object to allow customization of settings.
    def configure
      yield config
    end

    # Returns the configuration object, initializing it if necessary.
    def config
      @config ||= Config.new
    end
  end
end
