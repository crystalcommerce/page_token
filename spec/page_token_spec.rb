require 'spec_helper'
require 'page_token'

describe PageToken do
  shared_examples_for "configurable" do
    let(:redis) { mock("Redis") }

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
    end

    describe "#search" do

    end
  end
end
