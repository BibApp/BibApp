require File.dirname(__FILE__) + '/../spec_helper'

describe "Object should be extended with some useful methods" do

  before(:each) do
    @blanks = [nil, false, '', [], {}]
    @not_blanks = [true, 'c', [1], {:a => :b}]
  end

  it "should be able to return a given value if blank or a default if not" do
    @blanks.each do |blank|
      blank.if_blank(1).should == 1
    end
    @not_blanks.each do |not_blank|
      not_blank.if_blank(1).should be_nil
      not_blank.if_blank(1, 2).should == 2
    end
  end

  it "should be able to return itself if not blank and a default value otherwise" do
    @blanks.each do |blank|
      blank.self_or_blank_default(1).should == 1
    end
    @not_blanks.each do |not_blank|
      not_blank.self_or_blank_default(1).should == not_blank
    end
  end

end