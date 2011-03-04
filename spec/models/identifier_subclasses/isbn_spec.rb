require File.dirname(__FILE__) + '/../../spec_helper'

describe ISBN do

it "can return a list of formats" do
    ISBN.id_formats.should == [:isbn]
  end

  it "can produce a random valid ISBN" do
    10.times do
      ISBN.is_valid?(ISBN.random).should be_true
    end
  end

  it "can cleanup a potential ISBN" do
    ISBN.cleanup("  978  05 -joe9j6\t51617k fred\n8").should == '9780596516178'
  end

  it "can determine if an ISBN is valid, cleaning it beforehand" do
    #three variations on a valid number
    ISBN.is_valid?('9780596516178').should be_true
    ISBN.is_valid?('978-0-596-51617-8').should be_true
    ISBN.is_valid?('j9u7nk80more596516ju178nk').should be_true
    #then change the check digit
    ISBN.is_valid?('9780596516179').should be_false
  end

end
