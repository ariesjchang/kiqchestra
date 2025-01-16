# frozen_string_literal: true

module Kiqchestra
  # The ProgressStore class serves as a base interface for implementing custom
  # storage mechanisms for workflow progress in Kiqchestra. It defines two
  # abstract methods (`read_progress` and `write_progress`) that must be implemented
  # by subclasses.
  #
  # This allows flexibility in how progress is stored, enabling users to choose
  # between file-based, Redis-based, or any other storage system.
  #
  # Methods:
  # - `read_progress`: Abstract method to read progress from the store.
  # - `write_progress(progress)`: Abstract method to write progress to the store.
  #
  # Example Usage:
  #   class MyStore < Kiqchestra::ProgressStore
  #     def read_progress
  #       # Custom implementation
  #     end
  #
  #     def write_progress(progress)
  #       # Custom implementation
  #     end
  #   end
  class ProgressStore
    def read_progress
      raise NotImplementedError, "Subclasses must implement this method"
    end

    def write_progress(progress)
      raise NotImplementedError, "Subclasses must implement this method"
    end
  end
end
