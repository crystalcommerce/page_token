class PageToken
  module Utils
    def self.stringify_keys(hash)
      hash.inject({}) do |acc, (k, v)|
        acc[k.to_s] = v
        acc
      end
    end

    def self.hash_to_pairs(hash)
      hash.sort_by {|k, _| k.to_s}.map do |(k, v)|
        if v.is_a?(Hash)
          [k.to_s, hash_to_pairs(v)]
        else
          [k.to_s, v]
        end
      end
    end

    def self.stringify_keys_and_values(hash)
      hash.inject({}) do |acc, (k, v)|
        v = case v
            when Hash   then stringify_keys_and_values(v)
            when Symbol then v.to_s
            else v
            end
        acc[k.to_s] = v
        acc
      end
    end
  end
end
