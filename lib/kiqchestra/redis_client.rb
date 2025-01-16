# frozen_string_literal: true

require 'redis'

module Kiqchestra
  class RedisClient
    def self.client
      @client ||= Redis.new(url: ENV['REDIS_URL'] || 'redis://localhost:6379/0')
    end
  end
end
