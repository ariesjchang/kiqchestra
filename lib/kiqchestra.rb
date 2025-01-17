# frozen_string_literal: true

require "sidekiq"
require "kiqchestra/base_job"
require "kiqchestra/config"
require "kiqchestra/version"
require "kiqchestra/workflow"
require "kiqchestra/workflow_store"

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
