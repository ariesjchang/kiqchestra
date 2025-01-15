# frozen_string_literal: true

module RedisStore
    # Use Sidekiq's built-in Redis connection
    class << self
        def connector
            # Sidekiq automatically uses the configuration from the environment,
            # and you don't need to specify the host, port, or other settings manually.
            Sidekiq.redis { |conn| conn }
        end
    end
end
