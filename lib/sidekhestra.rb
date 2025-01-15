# frozen_string_literal: true

require "sidekiq"
require_relative "sidekhestra/version"
require_relative "sidekhestra/workflow"
require_relative "sidekhestra/base_worker"

# Sidekhestra is a Sidekiq-based job orchestration framework designed for
# workflows where tasks depend on the completion of other tasks.
# It simplifies the process of managing complex job dependencies, enabling developers
# to focus on business logic rather than the intricacies of dependency management.
module Sidekhestra
end
