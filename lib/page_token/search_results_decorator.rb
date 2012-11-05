require 'delegate'

class PageToken
  class SearchResultsDecorator < SimpleDelegator

    def initialize(search_generator, saved_search, results)
      @_search_generator = search_generator
      @_saved_search     = saved_search

      @_results          = results
      super(@_results)

      @_next_page        = _generate_next_page
    end

    def next_page_token
      _next_page && _next_page.token
    end

    def asc?
      _saved_search.asc?
    end

    def desc?
      _saved_search.desc?
    end

  private

    def _search_generator
      @_search_generator
    end

    def _saved_search
      @_saved_search
    end

    def _results
      @_results
    end

    def _next_page
      @_next_page
    end

    def _generate_next_page
      return nil if _last_page?

      @_next_page = _search_generator.generate(_next_page_options)
    end

    def _last_page?
      _results.length < _saved_search.limit
    end

    def new_last_id
      _results.last && _results.last.id
    end

    def _next_page_options
      {
        "limit" => _saved_search.limit,
        "order" => _saved_search.order,
        "last_id" => new_last_id,
        "search" => _saved_search.search,
      }
    end
  end
end
