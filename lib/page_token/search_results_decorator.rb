class PageToken
  class SearchResultsDecorator
    attr_reader :search_generator, :saved_search, :results

    def initialize(search_generator, saved_search, results)
      @search_generator = search_generator
      @saved_search     = saved_search
      @results          = results
    end

    #TODO: generate next page if applicable
  end
end
