require 'spec_helper'
require 'punctuated_pagination'

describe PunctuatedPagination do
  shared_examples_for "configurable" do
    let(:redis) { mock("Redis") }

    it "namespaces redis" do
      subject.configure do |config|
        config.connection = redis
      end

      subject.config.redis.redis.should == redis
    end

    it "defaults to the punctuated_pagination namespace" do
      subject.configure do |config|
        config.connection = redis
      end

      subject.config.redis.namespace.should == "punctuated_pagination"
    end

    it "allows you to override the punctuated pagination" do
      subject.configure do |config|
        config.connection = redis
        config.namespace = "something_else"
      end

      subject.config.redis.namespace.should == "something_else"
    end
  end

  context "global class interface" do
    subject { PunctuatedPagination }

    describe ".configure" do
      after(:each) do
        subject.clear_config!
      end

      it_should_behave_like "configurable"
    end
  end

  context "instance interface" do
    subject { PunctuatedPagination.new }

    describe "#configure" do
      it_should_behave_like "configurable"
    end
  end
end
