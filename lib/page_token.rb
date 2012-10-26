require "page_token/version"
require "page_token/config"
require "page_token/utils"
require "page_token/digestor"

class PageToken
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
    options = Utils.stringify_keys(options)
    options.delete("last_id") # not pertinent to first page
    options["order"] ||= :asc
    raise(ArgumentError, "Missing :limit")  unless options["limit"]
    raise(ArgumentError, "Missing :search") unless options["search"]
    Digestor.new(options).digest
  end
end
