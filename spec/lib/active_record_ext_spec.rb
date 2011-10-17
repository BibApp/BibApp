require File.dirname(__FILE__) + '/../spec_helper'

describe "Extend ActiveRecord and ActiveModel::Name with utility methods" do
  it "should make it easy to get a plural human name" do
    Work.model_name.human_pl.should == 'Works'
  end

end