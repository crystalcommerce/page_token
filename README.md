# page_token
[![Build Status](https://secure.travis-ci.org/crystalcommerce/page_token.png)](http://travis-ci.org/crystalcommerce/page_token)

TODO: Write a better gem description

Fairly hacky pattern that stores search placeholders in Redis. This is
intended for allowing predictable, token-based pagination for APIs. See the
Usage section for notes on requirements.

## Installation

TODO. Not currently on rubygems.

## Configuration
You can configure PageToken globally:

```ruby
PageToken.configure do |config|
  config.connection = Redis.new
  config.namespace  = "dem_tokens" # defaults to page_token
  config.ttl        = 60 * 5 # Search expiry. Not used if not specified
end

PageToken.search(...) {|search| ...}
```

Or into an instance:

```ruby
page_token = PageToken.new
page_token.configure do |config|
  #...
end

page_token.search(...) {|search| ...}
```


## Usage

TODO: Better usage documenation.

The main search API is the `PageToken.search` method. You should provided it:

1. Either a next page token string OR options for the search
2. A block that receives a search object and returns a page of results.

Some rules for use:
1. Results from the search need to conform to an Enumerable-like interface.
This should work for Arrays and for most pagination wrappers that I'm aware of.
2. Your database must have incrementing primary keys.
3. Your search cannot produce sparse pages. If it gets a page of results
smaller than the limit for the search, it will assume the search is done.
4. ID ordering must be fine. You can reverse it with the `order` option of
:desc.
5. Searches are not meant to be reversible. They are for taking a trip from
start to finish through the result set.
6. PageToken doesn't make any assumptions about how you search. You must sort
the results for each page appropriately.

### Simple Use Case
```ruby
default_search_options = {
  :limit => 20,
  :order => :asc,
  :search => params[:search]
}

results = PageToken.search(params[:next_page_token] ||
                           default_search_options) do |search|
  #search params will be some set of search params, i.e. a Hash
  if search.asc?
    order         = "id ASC"
    id_conditions = ["id > ?", search.last_id]
  else
    order         = "id DESC"
    id_conditions = ["id < ?", search.last_id]
  end

  Product.search(search.params).
          where(id_conditions).
          order(order).
          limit(search.limit)
end

results.length # => 20
results.next_page_token # => "1aee8e5532bd5463ba160b7b6269a9da"
results.some_crazy_method_your_search_lib_defines # => "Porkchop Sandwiches"
```

Note that if the given token is not found, `PageToken::TokenNotFound` will be
raised.

### Generating Token for First Page
You can also generate a token for the first page of a search. This is useful if
you have very complex search forms that require a POST so as not to produce a
too-long URI:

```ruby
token = PageToken.generate_first_page_token(:limit => 20,
                                            :search => {"name_like" => "joe"})
token # => 1aee8e5532bd5463ba160b7b6269a9da
redirect_to :search, :id => token
```

### Search Options
Search options *requires* the following options:

1. `:limit` - Positive, nonzero integer limit.
2. `:search` - Some search object that can be serialized into JSON. Note that
when deserialized, symbol keys will be converted into strings. If this a
problem, use ActiveSupport's HashWithIndifferentAccess if you've got it.

These options are optional:

1. `:order` - Either `:asc` or `:desc`. ID order. Defaults to `:asc`
2. `:last_id` - For some rare cases, you may want to specify the last ID seen
when beginning a search.

## Gotchas
Note that this tool uses Marshal to dump. That means that if you change ruby
versions, you could potentially end up with collisions.

## Contributing

1. Fork it
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Added some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create new Pull Request
