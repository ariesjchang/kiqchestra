# frozen_string_literal: true

require "redis"

module Kiqchestra
  # Provides a Redis-based storage solution for workflow dependencies and progress.
  # This client abstracts common read and write operations to Redis,
  # enabling Kiqchestra workflows to manage their state effectively.
  #
  # Dependencies:
  # - `redis` gem: Ensure this is included in your Gemfile.
  class RedisClient
    def self.client
      @client ||= Redis.new(url: ENV["REDIS_URL"] || "redis://localhost:6379/0")
    end
  end
end
