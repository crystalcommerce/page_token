require 'redis/namespace'

class PunctuatedPagination
  class ConfigError < StandardError; end

  class Config
    attr_reader :connection, :namespace, :redis

    def initialize
      @namespace = "punctuated_pagination"
    end

    def connection=(redis_conn)
      @redis = Redis::Namespace.new(namespace, :redis => redis_conn)
    end

    def namespace=(namespace)
      redis.namespace = namespace if redis
      @namespace = namespace
    end

    def validate!
      unless redis
        raise ConfigError, "You must specify redis during configuration."
      end
    end
  end
end
