require 'spec_helper'
require 'page_token/digestor'

describe PageToken::Digestor do
  let(:options) do
    {
      "limit"  => 100,
      "order"  => :asc,
      "search" => "foobar"
    }
  end

  subject { PageToken::Digestor.new(options) }

  describe "#digest" do
    it "coerces limit and order" do
      other_digestor = PageToken::Digestor.new(options.merge('limit' => "100",
                                                             'order' => 'asc'))
      subject.digest.should == other_digestor.digest
    end

    context "invalid order" do
      let(:options) do
        {
          "limit"  => 100,
          "order"  => 'wat',
          "search" => "foobar"
        }
      end

      it "raises an ArgumentError" do
        expect { subject.digest }.to raise_error(ArgumentError)
      end
    end
  end
end
