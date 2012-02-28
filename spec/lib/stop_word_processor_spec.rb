require File.dirname(__FILE__) + '/../spec_helper'
require 'stop_word_processor'

#note that we configure the stopword set in spec/support/stopwords.config

describe StopWordProcessor do
  describe "can tell if a word is a stopword" do
    it "should report 'a' as a stopword" do
      ['a', 'A'].each do |word|
        StopWordProcessor.instance.is_stopword?(word).should be_true
      end
    end

    it "should not report 'joe' as a stopword" do
      ['joe', 'Joe'].each do |word|
        StopWordProcessor.instance.is_stopword?(word).should be_false
      end
    end

    it "should be able to trim an array from the left" do
      StopWordProcessor.instance.trim_array_left(['a', 'the', 'joe', 'an']).should == ['joe', 'an']
    end

    it "trims a one element array to itself, even if the remaining word is a stopword" do
      StopWordProcessor.instance.trim_array_left(['The']).should == ['The']
    end

    it "should be able to trim a string from the left" do
      StopWordProcessor.instance.trim_string_left('A An Joe The').should == 'Joe The'
      StopWordProcessor.instance.trim_string_left('Joe The Bob').should == 'Joe The Bob'
      StopWordProcessor.instance.trim_string_left("A The").should == 'The'
    end
  end
end