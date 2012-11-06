require 'digest/md5'
require 'page_token/utils'

class PageToken
  class Digestor
    def initialize(options)
      @options = options
    end

    def digest
      limit   = options.fetch("limit").to_i
      order   = options.fetch("order").to_s
      last_id = options["last_id"]

      unless %w[asc desc].include?(order)
        raise ArgumentError, "Order must be asc or desc" 
      end

      search = options.fetch("search")
      serialized = serialized_options(limit, order, search, last_id)
      Digest::MD5.hexdigest(serialized)
    end

  private

    def serialized_options(limit, order, search, last_id)
      pairs = [["limit", limit],
               ["order", order],
               ["last_id", last_id],
               ["search", serialize_search(search)]]
      Marshal.dump(pairs)
    end

    def serialize_search(search)
      if search.is_a?(Hash)
        Utils.hash_to_pairs(search)
      else
        search
      end
    end

    def options
      @options
    end
  end
end
