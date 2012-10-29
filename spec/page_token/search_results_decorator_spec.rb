require 'spec_helper'
require 'page_token/search_results_decorator'

describe PageToken::SearchResultsDecorator do
  subject { PageToken::SearchResultsDecorator.new(results)}

  context "array-style results" do
    let(:results) { [stub(:id => 1), stub(:id => 2)] }

  end

  context "will-paginate style results" do

  end
end
