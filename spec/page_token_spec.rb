require 'spec_helper'
require 'page_token'

describe PageToken do
  let(:redis) { mock("Redis") }

  before(:each) do
    redis.stub(:set)
    redis.stub(:expire)
    redis.stub(:multi).and_yield
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
        md5 = subject.generate_first_page_token(:order => :asc,
                                                :limit => 100,
                                                :search => {:foo => "bar",
                                                            :bar => "baz"})
        md5.should == 'd7f2dbac1f23881f10d1677cd0535f76'
      end

      it "ignores extraneous options" do
        md5 = subject.generate_first_page_token(:order => :asc,
                                                :limit => 100,
                                                :pigs => 'yep',
                                                :search => {:foo => "bar",
                                                            :bar => "baz"})
        md5.should == 'd7f2dbac1f23881f10d1677cd0535f76'
      end

      it "ignores last_id option" do
        md5 = subject.generate_first_page_token(:order => :asc,
                                                :limit => 100,
                                                :last_id => 10,
                                                :search => {:foo => "bar",
                                                            :bar => "baz"})
        md5.should == 'd7f2dbac1f23881f10d1677cd0535f76'
      end

      it "coerces the expected types" do
        md5 = subject.generate_first_page_token("order" => "asc",
                                                "limit" => "100",
                                                "search" => {"foo" => "bar",
                                                             "bar" => "baz"})
        md5.should == 'd7f2dbac1f23881f10d1677cd0535f76'
      end

      it "defaults order to :asc" do
        md5 = subject.generate_first_page_token(:limit => 100,
                                                :search => {:foo => "bar",
                                                            :bar => "baz"})
        md5.should == 'd7f2dbac1f23881f10d1677cd0535f76'
      end

      it "writes to redis in a transaction" do
        redis.should_receive(:multi)
        redis.should_receive(:set) do |key, payload|
          key.should == 'page_token:d7f2dbac1f23881f10d1677cd0535f76'
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
                with('page_token:d7f2dbac1f23881f10d1677cd0535f76', 5)


          subject.generate_first_page_token(:limit => 100,
                                            :search => {:foo => "bar",
                                                        :bar => "baz"})
        end
      end
    end

    describe "#search" do
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
          subject.search(search) {}
        end

        it "yields a parsed search object" do
          yielded_search = nil

          subject.search(search) {|x| yielded_search = x}

          yielded_search.should be
          yielded_search.token.should == "somesearchtoken"
          yielded_search.limit.should == 100
          yielded_search.order.should == :asc
          yielded_search.last_id.should == 200
          yielded_search.params.should == {
            "name_like" => "example"
          }
        end

        it "creates a next page"

        context "key does not exist" do
          let(:stored_search) { nil }

        end
      end
    end
  end
end
