# frozen_string_literal: true

require "kiqchestra/default_workflow_store"

module Kiqchestra
  # The Config class provides a configuration object for Kiqchestra, allowing users
  # to customize various aspects of the library's behavior.
  #
  # By default, it initializes with a DefaultWorkflowStore instance for managing
  # workflow storage (dependencies, progress, etc.). Users can override this with
  # a custom store by setting the `workflow_store` attribute.
  #
  # Attributes:
  # - `workflow_store`: The object responsible for storing workflow-related data.
  #   Defaults to an instance of `DefaultWorkflowStore`.
  #
  # Example Usage:
  #   Kiqchestra.configure do |config|
  #     config.store = MyCustomWorkflowStore.new
  #   end
  class Config
    attr_accessor :store

    def initialize
      @store = DefaultWorkflowStore.new
    end
  end
end
