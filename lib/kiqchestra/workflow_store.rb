# frozen_string_literal: true

module Kiqchestra
  # The WorkflowStore class serves as an abstract base class for implementing
  # custom storage mechanisms for workflow progress, dependencies, and arguments.
  # It defines abstract methods that must be implemented by subclasses.
  #
  # By default, Kiqchestra uses DefaultWorkflowStore. Users are free to create
  # their own custom implementation of WorkflowStore to change storage system
  # (file-based, database, etc.) or specific details of implementations.
  class WorkflowStore
    # Ensures subclasses properly implement required methods.
    def initialize(*_args)
      # No initialization logic here
    end

    # Reads the dependencies for a workflow.
    #
    # @return [Hash] A hash representing the dependencies for the workflow, where each
    #                key is a task ID and the value is an array of dependent task IDs.
    # @raise [NotImplementedError] This method must be implemented by a subclass.
    def read_dependencies
      raise NotImplementedError, "Subclasses must implement the read_dependencies method"
    end

    # Writes the dependencies for a workflow to the store.
    #
    # @param dependencies [Hash] A hash representing the dependencies to store, where each key
    #                            is a task ID and the value is an array of dependent task IDs.
    # @example { a_job: { deps: [], args: [1, 2, 3] }, b_job: { deps: [:a_job], args: nil } }
    # @raise [NotImplementedError] This method must be implemented by a subclass.
    def write_dependencies(_dependencies)
      raise NotImplementedError, "Subclasses must implement the write_dependencies method"
    end

    # Reads the progress of a workflow.
    #
    # @return [Hash] A hash representing the progress of the workflow, where each key
    #                is a task ID and the value indicates the completion status.
    # @raise [NotImplementedError] This method must be implemented by a subclass.
    def read_progress
      raise NotImplementedError, "Subclasses must implement the read_progress method"
    end

    # Writes the progress of a workflow to the store.
    #
    # @param progress [Hash] A hash representing the progress to store, where each key
    #                        is a task ID and the value indicates the completion status.
    # @example { a_worker: 'complete', b_worker: 'in_progress' }
    # @raise [NotImplementedError] This method must be implemented by a subclass.
    def write_progress(_progress)
      raise NotImplementedError, "Subclasses must implement the write_progress method"
    end
  end
end
