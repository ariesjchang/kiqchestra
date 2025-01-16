# frozen_string_literal: true

require "kiqchestra/file_dependency_store"
require "kiqchestra/file_progress_store"

module Kiqchestra
  # The Config class provides a configuration object for Kiqchestra, allowing users
  # to customize various aspects of the library's behavior.
  #
  # By default, it initializes with a FileDependencyStore and a FileProgressStore
  # instance for storing workflow progress. Users can override this with a
  # custom store by setting the `dependency_store` or `progress_store` attribute.
  #
  # Attributes:
  # - `dependency_store`: The object responsible for storing workflow dependencies.
  #   Defaults to an instance of `FileDependencyStore`.
  # - `progress_store`: The object responsible for storing workflow progress.
  #   Defaults to an instance of `FileProgressStore`.
  #
  # Example Usage:
  #   Kiqchestra.configure do |config|
  #     config.dependency_store = MyCustomDependencyStore.new
  #     config.progress_store = MyCustomProgressStore.new
  #   end
  class Config
    attr_accessor :dependency_store, :progress_store

    # Save progress temporarily as a file by default
    def initialize
      @dependency_store = FileDependencyStore.new
      @progress_store = FileProgressStore.new
    end
  end
end
