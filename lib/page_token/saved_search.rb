require 'multi_json'

class PageToken
  class SavedSearch 
    def self.parse(token, json)
      new(token, MultiJson.decode(json))
    end

    attr_reader :token, :limit, :order, :search, :last_id

    def initialize(token, attrs = {})
      @token   = token
      @limit   = attrs.fetch('limit')
      @order   = attrs.fetch('order').to_sym
      @search  = attrs.fetch('search')
      @last_id = attrs['last_id']
    end

    def asc?
      order == :asc
    end

    def desc?
      order == :desc
    end
  end
end
