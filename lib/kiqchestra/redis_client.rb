# frozen_string_literal: true

require "redis"

module Kiqchestra
  # Redis client used for caching workflow dependencies and progress.
  #
  # Dependencies:
  # - `redis` gem: Ensure this is included in your Gemfile.
  class RedisClient
    def self.client
      @client ||= Redis.new(url: ENV["REDIS_URL"] || "redis://localhost:6379/0")
    end
  end
end
