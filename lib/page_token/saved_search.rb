class PageToken
  class SavedSearch 
    attr_reader :token, :limit, :order, :params, :last_id

    def initialize(token, attrs = {})
      @token   = token
      @limit   = attrs.fetch('limit')
      @order   = attrs.fetch('order').to_sym
      @params  = attrs.fetch('search')
      @last_id = attrs['search']
    end
  end
end
