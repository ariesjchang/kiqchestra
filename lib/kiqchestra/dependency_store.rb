# frozen_string_literal: true

module Kiqchestra
  # Abstract base class for dependency storage implementations.
  # Subclasses must implement the `read_dependencies` and `write_dependencies` methods.
  class DependencyStore
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
