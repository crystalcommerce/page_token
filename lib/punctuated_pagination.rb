require "punctuated_pagination/version"
require "punctuated_pagination/config"

class PunctuatedPagination
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
    @config
  end

  def clear_config!
    @config = Config.new
  end
end
