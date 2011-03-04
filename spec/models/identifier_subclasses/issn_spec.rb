require File.dirname(__FILE__) + '/../../spec_helper'

describe ISSN do

  it "can return a list of formats" do
    ISSN.id_formats.should == [:issn]
  end

  it "can produce a random valid ISSN" do
    10.times do
      ISSN.is_valid?(ISSN.random).should be_true
    end
  end

  it "can cleanup a potential ISSN" do
    ISSN.cleanup("  1234 -joe4j3\t2k1 fred\n").should == '12344321'
  end

  it "can determine if an ISSN is valid, cleaning it beforehand" do
    #three variations on a valid number
    ISSN.is_valid?('02122510').should be_true
    ISSN.is_valid?('0212-2510').should be_true
    ISSN.is_valid?('junk0212more-junk2510here').should be_true
    #then change the check digit
    ISSN.is_valid?('0212251X').should be_false
  end

end
