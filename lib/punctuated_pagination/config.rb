require 'redis/namespace'

class PunctuatedPagination
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
  end
end
