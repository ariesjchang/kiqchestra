# frozen_string_literal: true

require "json"
require "kiqchestra/progress_store"

module Kiqchestra
  # The FileProgressStore class is a default implementation of the ProgressStore
  # interface. It stores workflow progress in a JSON file on the filesystem.
  #
  # This is the default storage mechanism used by Kiqchestra if no custom
  # progress store is configured.
  #
  # Constructor:
  # - `initialize(file_path = "workflow_progress.json")`: Initializes the file store
  #   with the specified file path. Defaults to "workflow_progress.json".
  #
  # Methods:
  # - `read_progress`: Reads progress data from the specified file. Returns an
  #   empty hash if the file does not exist.
  # - `write_progress(progress)`: Writes the given progress data to the specified
  #   file in JSON format.
  #
  # Example Usage:
  #   store = Kiqchestra::FileProgressStore.new("custom_progress.json")
  #   store.write_progress({ job1: "complete" })
  #   progress = store.read_progress
  class FileProgressStore < ProgressStore
    def initialize(file_path = "tmp/kiqchestra/workflow_progress.json")
      super
      @file_path = file_path
    end

    def read_progress
      return {} unless File.exist?(@file_path)

      JSON.parse File.read(@file_path)
    end

    def write_progress(progress)
      File.write @file_path, progress.to_json
    end
  end
end
