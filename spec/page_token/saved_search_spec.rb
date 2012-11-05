require 'spec_helper'
require 'page_token/saved_search'

describe PageToken::SavedSearch do
  subject do
    PageToken::SavedSearch.new("SOMETOK", "limit"   => 100,
                                          "order"   => "asc",
                                          "search"  => "SOMESEARCH",
                                          "last_id" => 45)
  end

  its(:token)   { should == "SOMETOK" }
  its(:limit)   { should == 100}
  its(:order)   { should == :asc}
  its(:search)  { should == "SOMESEARCH"}
  its(:last_id) { should == 45}
  its(:asc?)    { should be_true }
  its(:desc?)   { should be_false }
end
