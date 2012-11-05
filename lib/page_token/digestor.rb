require 'digest/md5'

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
      serialized = serialized_options(limit, order, search)
      Digest::MD5.hexdigest(serialized)
    end

  private

    def serialized_options(limit, order, search, last_id)
      pairs = [["limit", limit],
               ["order", order],
               ["last_id", last_id],
               ["search", Utils.hash_to_pairs(search)]]
      Marshal.dump(pairs)
    end

    def options
      @options
    end
  end
end
