require File.dirname(__FILE__) + '/../spec_helper'

describe KeywordCloudHelper do

  describe "set_keywords should return a sorted array of structs with name and count values" do

    it "should return an empty array if the facets have no keywords" do
      helper.set_keywords({}).should be_empty
    end

    it "should return a sorted array when facets has keywords" do
      keyword = Struct.new(:name, :value)
      keywords = helper.set_keywords({:keywords => [
        keyword.new('one', 6),
        keyword.new('two', 2),
        keyword.new('three', 3)
      ]})
      keywords.length.should == 3
      keywords.first.name.should == 'one'
      keywords.last.name.should == 'two'
      keywords.first.count.should == 5
      keywords.last.count.should == 2
    end

  end

end
