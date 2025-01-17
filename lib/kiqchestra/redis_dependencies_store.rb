# frozen_string_literal: true

require "json"
require "kiqchestra/dependencies_store"
require "kiqchestra/redis_client"

module Kiqchestra
  # The RedisDependenciesStore class is an implementation of the
  # DependenciesStore interface. It stores task dependencies in a Redis key.
  #
  # Example Usage:
  #   store = Kiqchestra::RedisDependenciesStore.new
  #   store.write_dependencies 'workflow_123',
  #                            { a_job: { deps: [], args: [1, 2, 3] },
  #                              b_job: { deps: [:a_worker], args: nil } }
  #   dependencies = store.read_dependencies 'workflow_123'
  class RedisDependenciesStore < DependenciesStore
    # Reads the dependencies for a specific workflow from Redis.
    #
    # @param workflow_id [String] The workflow ID to retrieve dependencies for.
    # @return [Hash] The dependencies of the workflow.
    def read_dependencies(workflow_id)
      raw_data = Kiqchestra::RedisClient.client.get workflow_dependencies_key(workflow_id)
      JSON.parse(raw_data || "{}")
    end

    # Writes the dependencies data for a specific workflow to Redis.
    # By default, keys are set with a TTL of 7 days.
    #
    # @param workflow_id [String] The workflow ID to store dependencies for.
    # @param dependencies [Hash] The dependencies data to store.
    def write_dependencies(workflow_id, dependencies)
      Kiqchestra::RedisClient.client.set workflow_dependencies_key(workflow_id),
                                         dependencies.to_json,
                                         ex: 604_800 # 7 days
    end

    private

    def workflow_dependencies_key(workflow_id)
      "workflow:#{workflow_id}:dependencies"
    end
  end
end
