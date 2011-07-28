require File.dirname(__FILE__) + '/../spec_helper'
require 'lib/trivial_initializer'

describe TrivialInitializer do

  before(:all) do
    @test_class = Class.new do
      attr_accessor :x, :y
      include TrivialInitializer
    end
  end

  it "should be able to initialize from a hash" do
    object = @test_class.new(:x => 10, :y => 'fred')
    object.x.should == 10
    object.y.should == 'fred'
  end

end
