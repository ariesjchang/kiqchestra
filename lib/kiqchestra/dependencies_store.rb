# frozen_string_literal: true

module Kiqchestra
  # The DependenciesStore class serves as an abstract base class for implementing
  # custom storage mechanisms for workflow progress in Kiqchestra. It defines two
  # abstract methods (`read_dependencies` and `write_dependencies`) that must be
  # implemented by subclasses.
  #
  # This allows flexibility in how progress is stored, enabling users to choose
  # between file-based, Redis-based, or any other storage system.
  #
  # Methods:
  # - `read_dependencies(workflow_id)`: Reads task dependencies for a specific workflow.
  # - `write_dependencies(workflow_id, dependencies)`: Caches the task dependencies for a specific workflow.
  class DependenciesStore
    # Ensures subclasses properly implement required methods.
    def initialize(*_args)
      # No initialization logic here
    end

    def read_dependencies
      raise NotImplementedError, "Subclasses must implement the read_dependencies method"
    end

    def write_dependencies(_dependencies)
      raise NotImplementedError, "Subclasses must implement the write_dependencies method"
    end
  end
end
