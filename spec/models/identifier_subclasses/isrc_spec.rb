require File.dirname(__FILE__) + '/../../spec_helper'

describe ISRC do

  it "can return a list of formats" do
    ISRC.id_formats.should == [:isrc]
  end

end