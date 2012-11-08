require 'spec_helper'
require 'page_token'

describe PageToken do
  let(:redis) { mock("Redis") }
  let(:digestor) { mock("Digestor", :digest => "SOMEDIGEST") }

  before(:each) do
    redis.stub(:set)
    redis.stub(:expire)
    redis.stub(:multi).and_yield

    PageToken::Digestor.stub(:new).and_return(digestor)
  end

  shared_examples_for "configurable" do
    it "namespaces redis" do
      subject.configure do |config|
        config.connection = redis
      end

      subject.config.redis.redis.should == redis
    end

    it "defaults to the page_token namespace" do
      subject.configure do |config|
        config.connection = redis
      end

      subject.config.redis.namespace.should == "page_token"
    end

    it "allows you to override the punctuated pagination" do
      subject.configure do |config|
        config.connection = redis
        config.namespace = "something_else"
      end

      subject.config.redis.namespace.should == "something_else"
    end

    it "defaults to no timeout" do
      subject.configure do |config|
        config.connection = redis
      end

      subject.config.ttl.should be_nil
    end

    it "allows you to override ttl in seconds" do
      subject.configure do |config|
        config.connection = redis
        config.ttl = 5
      end

      subject.config.ttl.should == 5
    end

    it "allows explicitly setting nil ttl" do
      subject.configure do |config|
        config.connection = redis
        config.ttl = nil
      end

      subject.config.ttl.should be_nil
    end

    context "incomplete configuration" do
      it "raises a PageToken::ConfigError" do
        expect do
          subject.configure do |config|
            config.namespace = "something_else"
          end
        end.to raise_error(PageToken::ConfigError)
      end
    end
  end

  context "global class interface" do
    subject { PageToken }

    describe ".configure" do
      after(:each) do
        subject.clear_config!
      end

      it_should_behave_like "configurable"
    end
  end

  context "instance interface" do
    subject { PageToken.new }

    describe "#configure" do
      it_should_behave_like "configurable"
    end

    describe "#generate_first_page_token" do

      before(:each) do
        subject.configure do |config|
          config.connection = redis
        end
      end

      it "generates a deterministic md5" do
        PageToken::Digestor.should_receive(:new).
          with("order" => :asc,
               "limit" => 100,
               "search" => {:foo => "bar", :bar => "baz"})
        subject.generate_first_page_token(:order => :asc,
                                                :limit => 100,
                                                :search => {:foo => "bar",
                                                            :bar => "baz"})
      end

      it "returns them digest" do
        subject.generate_first_page_token(:order => :asc,
                                                :limit => 100,
                                                :search => {:foo => "bar",
                                                            :bar => "baz"}).
          should == "SOMEDIGEST"
      end

      it "leaves removal of bogus options to the digestor" do
        PageToken::Digestor.should_receive(:new).
          with("order"  => :asc,
               "limit"  => 100,
               "pigs"   => "yep",
               "search" => {:foo => "bar", :bar => "baz"})
        subject.generate_first_page_token(:order => :asc,
                                                :limit => 100,
                                                :pigs => 'yep',
                                                :search => {:foo => "bar",
                                                            :bar => "baz"})
      end

      it "removes the last_id option because it is invalid here" do
        PageToken::Digestor.should_receive(:new).
          with("order" => :asc,
               "limit" => 100,
               "search" => {:foo => "bar", :bar => "baz"})
        subject.generate_first_page_token(:order => :asc,
                                          :limit => 100,
                                          :last_id => 10,
                                          :search => {:foo => "bar",
                                                      :bar => "baz"})
      end

      it "defaults order to :asc" do
        PageToken::Digestor.should_receive(:new).
          with("order" => :asc,
               "limit" => 100,
               "search" => {:foo => "bar", :bar => "baz"})
        subject.generate_first_page_token(:limit => 100,
                                          :search => {:foo => "bar",
                                                      :bar => "baz"})
      end

      it "allows an explicitly nil search" do
        expect {
          subject.generate_first_page_token(:limit  => 100,
                                            :search => nil)
        }.to_not raise_error
      end

      it "does not allow a missing search option" do
        expect {
          subject.generate_first_page_token(:limit  => 100)
        }.to raise_error(ArgumentError)
      end

      it "does not allow a nil limit option" do
        expect {
          subject.generate_first_page_token(:limit => nil)
        }.to raise_error(ArgumentError)
      end

      it "writes to redis in a transaction" do
        redis.should_receive(:multi)
        redis.should_receive(:set) do |key, payload|
          key.should == 'page_token:SOMEDIGEST'
          MultiJson.decode(payload).should == {
            "limit" => 100,
            "order" => "asc",
            "search" => {
              "foo" => "bar",
              "bar" => "baz",
            }
          }
        end

        subject.generate_first_page_token(:limit => 100,
                                          :search => {:foo => "bar",
                                                      :bar => "baz"})
      end

      it "does not set a timestamp by default" do
        redis.should_not_receive(:expire)

        subject.generate_first_page_token(:limit => 100,
                                          :search => {:foo => "bar",
                                                      :bar => "baz"})
      end

      context "ttl is set" do
        before(:each) do
          subject.configure do |config|
            config.ttl = 5
          end
        end

        it "sets the ttl" do
          redis.should_receive(:expire).
                with('page_token:SOMEDIGEST', 5)


          subject.generate_first_page_token(:limit => 100,
                                            :search => {:foo => "bar",
                                                        :bar => "baz"})
        end
      end
    end

    describe "#search" do
      before(:each) do
        subject.configure do |config|
          config.connection = redis
        end
      end

      shared_examples_for "search result decoration" do
        it "returns a decorated set of search results" do
          result = mock("Result")
          decorated = subject.search(search) {|_| [result]}
          decorated.length.should == 1
          decorated.first.should == result
          decorated.next_page_token.should == nil
        end
      end

      context "key given" do
        let(:search) { "somesearchtoken" }
        let(:stored_search) do
          MultiJson.dump({
            "limit" => 100,
            "order" => "asc",
            "last_id" => 200,
            "search" => {
              "name_like" => "example"
            }
          })
        end

        before(:each) do
          redis.stub(:get).and_return(stored_search)
        end
        
        it "finds the key in redis" do
          redis.should_receive(:get).with("page_token:somesearchtoken")
          subject.search(search) {|_| [] }
        end

        it "yields a parsed search object" do
          yielded_search = nil

          subject.search(search) {|x| yielded_search = x; []}

          yielded_search.should be
          yielded_search.token.should == "somesearchtoken"
          yielded_search.limit.should == 100
          yielded_search.order.should == :asc
          yielded_search.last_id.should == 200
          yielded_search.search.should == {
            "name_like" => "example"
          }
        end

        it_should_behave_like "search result decoration"

        context "key does not exist" do
          let(:stored_search) { nil }

          it "raises an error" do
            expect {
              subject.search("BOGUS") {|_| }
            }.to raise_error(PageToken::TokenNotFound, "Token BOGUS not found.")
          end
        end
      end

      context "search given" do
        let(:search) do
          {
            "limit" => 100,
            "order" => "asc",
            "last_id" => 200,
            "search" => {
              "name_like" => "example"
            }
          }
        end

        it "yields in the search" do
          yielded_search = nil

          subject.search(search) {|x| yielded_search = x; []}

          yielded_search.should be
          yielded_search.token.should be_nil
          yielded_search.limit.should == 100
          yielded_search.order.should == :asc
          yielded_search.last_id.should == 200
          yielded_search.search.should == {
            "name_like" => "example"
          }
        end

        it_should_behave_like "search result decoration"

        it "generates the next page given the search result" do
          generator = mock("Saved Search Generator")
          PageToken::SavedSearchGenerator.stub(:new).and_return(generator)
          generator.should_receive(:generate).
            with(hash_including("last_id" => 2)).
            and_return(mock("Saved Search", :token => "NEWTOK"))
          results = subject.search(search.merge("limit" => 2)) {
            [stub(:id => 1), stub(:id => 2)]
          }

          results.next_page_token.should == "NEWTOK"
        end
      end
    end
  end
end
