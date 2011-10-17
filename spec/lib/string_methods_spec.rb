require File.dirname(__FILE__) + '/../spec_helper'
require 'string_methods'

describe StringMethods do
  describe "Provides methods for dealing with string encoding" do
    it "should be able to recognize a valid UTF8 string and return it" do
      StringMethods.ensure_utf8("A normal string").should == "A normal string"
    end

    describe "non UTF8 strings" do
      it "should be able to recognize and convert some non-UTF8 encoded strings" do
        StringMethods.ensure_utf8("\xa4").should == "§"
      end

      it "should throw an exception if it cannot recognize the encoding" do
        str = "non-utf stub for failing string\xa4"
        CMess::GuessEncoding::Automatic.should_receive(:guess).with(str).and_return(nil)
        lambda {StringMethods.ensure_utf8(str)}.should raise_exception(EncodingException)
      end

    end
  end
end