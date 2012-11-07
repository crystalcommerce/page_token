require 'spec_helper'
require 'page_token/search_results_decorator'

describe PageToken::SearchResultsDecorator do
  let(:limit) { 2 }
  let(:saved_search) { mock("Saved Search", :limit  => limit,
                                            :order  => :asc,
                                            :search => {"foo" => "bar"}) }
  let(:search_generator) { mock("Search Generator") }
  subject { PageToken::SearchResultsDecorator.new(search_generator,
                                                  saved_search,
                                                  results)}

  shared_examples_for "no next_page_token" do
    it "does not attempt to generate a new token with the generator" do
      search_generator.should_not_receive(:generate)
    end

    its(:next_page_token) { should be_nil }
  end

  shared_examples_for "generates next page of results" do
    let(:new_saved_search) { mock("New Saved Search", :token => "NEWTOK") }

    before(:each) do
      search_generator.stub(:generate).and_return(new_saved_search)
    end

    it "generates the next page with the correct options" do
      search_generator.should_receive(:generate).
        with("limit" => limit,
             "order" => :asc,
             "search" => {"foo" => "bar"},
             "last_id" => 2)

      PageToken::SearchResultsDecorator.new(search_generator,
                                            saved_search,
                                            results)
    end

    it "delegates to the result set for everything" do
      subject.length.should == 2
      subject.first.id.should == 1
    end

    its(:next_page_token) { should == "NEWTOK" }
    its(:limit)           { should == 2        }
  end

  context "array-style results" do
    let(:results) { [stub(:id => 1), stub(:id => 2)] }

    it_should_behave_like "generates next page of results"

    context "final page" do
      let(:limit) { 5 }

      it_should_behave_like "no next_page_token"
      its(:limit) { should == 5 }
    end
  end

  context "will-paginate style results" do
    let(:first_order) { mock("first order", :id => 1)}
    let(:last_order) { mock("last order", :id => 2)}
    let(:results) { mock("WillPaginate::Collection", :length => 2,
                                                     :first => first_order,
                                                     :last => last_order) }

    it_should_behave_like "generates next page of results"
    context "final page" do
      let(:limit) { 5 }
      it_should_behave_like "no next_page_token"
      its(:limit) { should == 5 }
    end
  end
end
