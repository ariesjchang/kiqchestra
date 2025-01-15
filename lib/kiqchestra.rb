# frozen_string_literal: true

require "sidekiq"
require_relative "kiqchestra/version"
require_relative "kiqchestra/workflow"
require_relative "kiqchestra/base_worker"

# Kiqchestra is a Sidekiq-based job orchestration framework designed for
# workflows where tasks depend on the completion of other tasks.
# It simplifies the process of managing complex job dependencies, enabling developers
# to focus on business logic rather than the intricacies of dependency management.
module Kiqchestra
end
