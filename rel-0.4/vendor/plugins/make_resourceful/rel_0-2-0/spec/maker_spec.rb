require File.dirname(__FILE__) + '/spec_helper'

describe Resourceful::Maker, "when extended" do
  include ControllerMocks
  before(:each) { mock_kontroller }

  it "should create an empty, inheritable callbacks hash" do
    @kontroller.read_inheritable_attribute(:resourceful_callbacks).should == {}
  end

  it "should create an empty, inheritable responses hash" do
    @kontroller.read_inheritable_attribute(:resourceful_responses).should == {}
  end

  it "should create an empty, inheritable parents array" do
    @kontroller.read_inheritable_attribute(:parents).should == []
  end
end

describe Resourceful::Maker, "when made_resourceful" do
  include ControllerMocks
  before(:each) do
    mock_kontroller
    mock_builder
  end

  it "should include Resourceful::Base" do
    @kontroller.expects(:include).with(Resourceful::Base)
    @kontroller.make_resourceful {}
  end

  it "should use Resourceful::Builder to build the controller" do
    Resourceful::Builder.expects(:new).with(@kontroller).returns(@builder)
    @kontroller.make_resourceful {}
  end

  it "should evaluate the made_resourceful callbacks in the context of the builder" do
    procs = (1..5).map { should_be_called { with(@builder) } }
    Resourceful::Base.stubs(:made_resourceful).returns(procs)
    @kontroller.make_resourceful {}
  end

  it "should evaluate the :include callback in the context of the builder" do
    @kontroller.make_resourceful(:include => should_be_called { with(@builder) }) {}
  end

  it "should evaluate the given block in the context of the builder" do
    @kontroller.make_resourceful(&(should_be_called { with(@builder) }))
  end
end

describe Resourceful::Maker, "after being made_resourceful" do
  include ControllerMocks
  before(:each) { mock_kontroller }

  it "should have methods from Resourceful::Default" do
    @kontroller.make_resourceful {}
    @kontroller.should respond_to?(:current_object)
    @kontroller.should respond_to?(:set_default_flash)
    @kontroller.should respond_to?(:response_for)
    @kontroller.should respond_to?(:object_path)
  end
end
