# frozen_string_literal: true

require "json"
require "kiqchestra/redis_client"
require "kiqchestra/workflow_store"

module Kiqchestra
  # The DefaultWorkflowStore class is the default implementation of WorkflowStore
  # for storing workflow dependencies, progress, and arguments in a Redis-backed store.
  #
  # This implementation uses Redis for persistence, providing an efficient and
  # scalable storage system for workflows. Users can customize this by implementing
  # their own subclass of WorkflowStore if needed.
  #
  # Example Usage:
  #   store = Kiqchestra::DefaultWorkflowStore.new
  #   store.write_metadata "workflow_123", { a_job: { deps: [], args: [1, 2, 3] } }
  #   metadata = store.read_metadata "workflow_123"
  #   store.write_progress "workflow_123", { a_job: "complete" }
  #   progress = store.read_progress "workflow_123"
  class DefaultWorkflowStore < WorkflowStore
    # Reads the metadata for a workflow from Redis.
    #
    # @param workflow_id [String] The workflow ID to retrieve workflow data for.
    # @return [Hash] A hash representing the workflow metadata, where each key is
    #                a task ID and the value is a hash with keys `:deps` and `:args`.
    def read_metadata(workflow_id)
      raw_data = Kiqchestra::RedisClient.client.get metadata_key(workflow_id)
      JSON.parse(raw_data || "{}")
    end

    # Writes the metadata for a workflow to Redis.
    #
    # @param workflow_id [String] The workflow ID to store dependencies for.
    # @param metadata [Hash] A hash representing the metadata to store.
    # @example { a_job: { deps: [], args: [1, 2, 3] }, b_job: { deps: [:a_job], args: nil } }
    def write_metadata(workflow_id, metadata)
      Kiqchestra::RedisClient.client.set metadata_key(workflow_id),
                                         metadata.to_json,
                                         ex: 604_800 # Default TTL: 7 days
    end

    # Reads the progress of a workflow from Redis.
    #
    # @param workflow_id [String] The workflow ID to retrieve progress for.
    # @return [Hash] A hash representing the progress of the workflow, where each
    #                key is a task ID and the value indicates the status.
    def read_progress(workflow_id)
      raw_data = Kiqchestra::RedisClient.client.get progress_key(workflow_id)
      JSON.parse(raw_data || "{}")
    end

    # Writes the progress of a workflow to Redis.
    #
    # @param workflow_id [String] The workflow ID to store progress for.
    # @param progress [Hash] A hash representing the progress to store.
    # @example { a_worker: "complete", b_worker: "in_progress" }
    def write_progress(workflow_id, progress)
      Kiqchestra::RedisClient.client.set progress_key(workflow_id),
                                         progress.to_json,
                                         ex: 604_800 # Default TTL: 7 days
    end

    private

    # Generates the Redis key for storing metadata of a specific workflow.
    #
    # @param workflow_id [String] The workflow ID.
    # @return [String] The Redis key for metadata.
    def metadata_key(workflow_id)
      "workflow:#{workflow_id}:metadata"
    end

    # Generates the Redis key for storing progress of a specific workflow.
    #
    # @param workflow_id [String] The workflow ID.
    # @return [String] The Redis key for progress.
    def progress_key(workflow_id)
      "workflow:#{workflow_id}:progress"
    end
  end
end
