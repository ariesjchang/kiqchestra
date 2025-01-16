# frozen_string_literal: true

require "json"
require "fileutils"
require_relative "dependency_store"

module Kiqchestra
  # A file-based implementation of dependency storage for Kiqchestra workflows.
  #
  # This class stores task dependencies as JSON data in a specified file.
  class FileDependencyStore < DependencyStore
    def initialize(file_path = "tmp/kiqchestra/workflow_dependencies.json")
      @file_path = file_path
    end

    # Reads the task dependencies from the specified JSON file.
    # 
    # @return [Hash] A hash of task dependencies, or an empty hash if the file does not exist.
    def read_dependencies
      return {} unless File.exist?(@file_path)

      JSON.parse File.read(@file_path)
    end

    # Writes the given task dependencies to the specified JSON file.
    # Ensures that the file and its parent directories are created if they do not exist.
    # 
    # @param [Hash] dependencies A hash of task dependencies to save.
    def write_dependencies(dependencies)
      # Ensure the directory exists
      FileUtils.mkdir_p File.dirname(@file_path)

      # Write the dependencies to the file
      File.write @file_path, dependencies.to_json
    end
  end
end
