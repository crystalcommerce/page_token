require 'spec_helper'
require 'page_token/utils'

describe PageToken::Utils do
  subject { PageToken::Utils }

  describe ".hash_to_pairs" do
    it "handles the empty case" do
      subject.hash_to_pairs({}).should == []
    end

    it "handles hashes with heterogenous types" do
      subject.hash_to_pairs({'foo' => "bar",
                             :wat => 7,
                             :a => "c"}).should == [
        ["a", "c"],
        ["foo", "bar"],
        ["wat", 7]
      ]
    end

    it "handles nested hashes" do
      subject.hash_to_pairs({:z => {"deeply" => {"nested" => "hash",
                                                 "a" => "b"}},
                             :wat => 7,
                             :huh => {"also" => "nested"}}).should == [
        ["huh", [["also", "nested"]]],
        ["wat", 7],
        ["z", [["deeply", [["a", "b"],["nested", "hash"]]]]]
      ]
    end
  end

  describe "stringify_keys_and_values" do
    it "handles the empty case" do
      subject.stringify_keys_and_values({}).should == {}
    end

    it "converts keys and values" do
      subject.stringify_keys_and_values({:foo => :bar, :bar => "baz"}).
        should == {"foo" => "bar", "bar" => "baz"}
    end

    it "handles nested hashes" do
      subject.stringify_keys_and_values({:foo => :bar, :bar => {"baz" => :blargh}}).
        should == {"foo" => "bar", "bar" => {"baz" => "blargh"}}
    end
  end
end
