require 'multi_json'
require 'forwardable'
require "page_token/version"
require "page_token/config"
require "page_token/utils"
require "page_token/digestor"

class PageToken
  extend Forwardable

  class << self
    def respond_to?(method, include_private=false)
      super || instance.respond_to?(method, include_private)
    end

    def method_missing(method, *args, &block)
      if instance.respond_to?(method)
        instance.send(method, *args, &block)
      else
        super
      end
    end

    def instance
      @instance ||= new
    end
  end

  attr_reader :config

  def_delegators :config, :redis, :ttl

  def configure(&block)
    @config ||= Config.new
    block.call(@config)
    @config.validate!
    @config
  end

  def clear_config!
    @config = Config.new
  end

  # options required:
  # :limit - positive integer limit
  # :search - hash of search params
  # optional arguments:
  # :order - either :asc or :desc, defaults to :asc
  def generate_first_page_token(options)
    options = normalize_options(options)
    validate_options(options)
    key = generate_key(options)
    
    redis.multi do
      redis.set(key, render_payload(options))
      redis.expire(key, ttl) if use_ttl?
    end

    key
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
    options.delete("last_id") # not pertinent to first page
    options["order"] ||= :asc
    options
  end

  def validate_options(options)
    raise(ArgumentError, "Missing :limit")  unless options["limit"]
    raise(ArgumentError, "Missing :search") unless options["search"]
  end

end
