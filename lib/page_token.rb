require 'multi_json'
require 'forwardable'
require "page_token/version"
require "page_token/config"
require "page_token/utils"
require "page_token/saved_search_generator"
require "page_token/search_results_decorator"

class PageToken
  extend Forwardable

  class TokenNotFound < StandardError
    def initialize(token)
      @token = token
    end

    def message
      "Token #{token} not found."
    end
  end

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
    generate_search(options).token
  end

  def search(token_or_search_options, &block)
    if is_token?(token_or_search_options)
      retrieve_search(token_or_search_options, &block)
    else
      #generate_search(token_or_search_options)
      #TODO: do search in block, store it, generate next page, return decorated
    end
  end

private

  def is_token?(token_or_search_options)
    token_or_search_options.is_a?(String)
  end

  def retrieve_search(token, &block)
    if str = redis.get(token)
      saved_search = SavedSearch.parse(token, str)
      results = block.call(saved_search)
      SearchResultsDecorator.new(search_generator, saved_search, results)
    else
      raise TokenNotFound.new(token)
    end
  end

  def generate_search(search_options)
    search_generator.generate(search_options)
  end

  def search_generator
    SavedSearchGenerator.new(redis, ttl)
  end
end
