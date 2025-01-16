# frozen_string_literal: true

require "kiqchestra/redis_dependencies_store"
require "kiqchestra/redis_progress_store"

module Kiqchestra
  # The Config class provides a configuration object for Kiqchestra, allowing users
  # to customize various aspects of the library's behavior.
  #
  # By default, it initializes with a RedisDependenciesStore and a RedisProgressStore
  # instance for storing workflow progress. Users can override this with a
  # custom store by setting the `dependencies_store` or `progress_store` attribute.
  #
  # Attributes:
  # - `dependencies_store`: The object responsible for storing workflow dependencies.
  #   Defaults to an instance of `RedisDependenciesStore`.
  # - `progress_store`: The object responsible for storing workflow progress.
  #   Defaults to an instance of `RedisProgressStore`.
  #
  # Example Usage:
  #   Kiqchestra.configure do |config|
  #     config.dependencies_store = MyCustomDependenciesStore.new
  #     config.progress_store = MyCustomProgressStore.new
  #   end
  class Config
    attr_accessor :dependencies_store, :progress_store

    # Save progress temporarily as a file by default
    def initialize
      @dependencies_store = RedisDependenciesStore.new
      @progress_store = RedisProgressStore.new
    end
  end
end
