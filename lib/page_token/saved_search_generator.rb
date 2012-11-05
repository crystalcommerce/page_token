require "page_token/utils"
require "page_token/digestor"
require "page_token/saved_search"

class PageToken
  class SavedSearchGenerator
    attr_reader :redis, :ttl

    def initialize(redis, ttl)
      @redis = redis
      @ttl   = ttl
    end

    def generate(options)
      options = normalize_options(options)
      validate_options(options)
      key = generate_key(options)

      redis.multi do
        redis.set(key, render_payload(options))
        redis.expire(key, ttl) if use_ttl?
      end

      SavedSearch.new(key, options)
    end

  private
    def render_payload(options)
      MultiJson.dump(Utils.stringify_keys_and_values(options))
    end

    def use_ttl?
      !!ttl
    end

    def generate_key(options)
      Digestor.new(options).digest
    end

    def normalize_options(options)
      options = Utils.stringify_keys(options)
      options["order"] ||= :asc
      options
    end

    def validate_options(options)
      raise(ArgumentError, "Missing :limit")  unless options["limit"]
      raise(ArgumentError, "Missing :search") unless options["search"]
    end
  end
end
