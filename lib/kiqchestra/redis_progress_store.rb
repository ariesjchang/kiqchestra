# frozen_string_literal: true

require "json"
require "kiqchestra/progress_store"
require "kiqchestra/redis_client"

module Kiqchestra
  # The RedisProgressStore class is a default implementation of the ProgressStore
  # interface. It stores workflow progress in a Redis key.
  #
  # This is the default storage mechanism used by Kiqchestra if no custom
  # progress store is configured.
  #
  # Methods:
  # - `read_progress`: Reads progress data, returns an empty hash if nonexistent.
  # - `write_progress(progress)`: Caches the given progress data
  #
  # Example Usage:
  #   store = Kiqchestra::RedisProgressStore.new
  #   store.write_progress 'workflow_123', { job1: "complete" }
  #   progress = store.read_progress 'workflow_123'
  class RedisProgressStore < ProgressStore
    # Reads the progress for a specific workflow from Redis.
    #
    # @param workflow_id [String] The workflow ID to retrieve progress for.
    # @return [Hash] The current progress of the workflow.
    def read_progress(workflow_id)
      raw_data = Kiqchestra::RedisClient.client.get workflow_progress_key(workflow_id)
      JSON.parse(raw_data || "{}")
    end

    # Writes the progress data for a specific workflow to Redis.
    # By default, keys are set with a TTL of 7 days.
    #
    # @param workflow_id [String] The workflow ID to store progress for.
    # @param progress [Hash] The progress data to store.
    def write_progress(workflow_id, progress)
      Kiqchestra::RedisClient.client.set workflow_progress_key(workflow_id),
                                         progress.to_json,
                                         ex: 604_800 # 7 days
    end

    private

    def workflow_progress_key(workflow_id)
      "workflow:#{workflow_id}:progress"
    end
  end
end
