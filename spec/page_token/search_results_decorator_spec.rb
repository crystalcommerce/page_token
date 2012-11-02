require 'spec_helper'
require 'page_token/search_results_decorator'

describe PageToken::SearchResultsDecorator do
  subject { PageToken::SearchResultsDecorator.new(results)}

  shared_examples_for "no next_page_token" do
    it "does not attempt to generate a new token with the generator"
    its(:next_page_token) { should be_nil }
  end

  context "array-style results" do
    let(:results) { [stub(:id => 1), stub(:id => 2)] }


    context "final page" do
      let(:limit) { 5 }

      it_should_behave_like "no next_page_token"
    end
  end

  context "will-paginate style results" do
    context "final page" do
      it_should_behave_like "no next_page_token"
    end
  end
end
