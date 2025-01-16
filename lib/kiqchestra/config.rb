# frozen_string_literal: true

module Kiqchestra
  # The Config class provides a configuration object for Kiqchestra, allowing users
  # to customize various aspects of the library's behavior.
  #
  # By default, it initializes with a FileProgressStore instance for storing
  # workflow progress. Users can override this with a custom store by setting the
  # `progress_store` attribute.
  #
  # Attributes:
  # - `progress_store`: The object responsible for storing workflow progress.
  #   Defaults to an instance of `FileProgressStore`.
  #
  # Example Usage:
  #   Kiqchestra.configure do |config|
  #     config.progress_store = MyCustomProgressStore.new
  #   end
  class Config
    attr_accessor :progress_store

    # Save progress temporarily as a file by default
    def initialize
      @progress_store = FileProgressStore.new
    end
  end
end
