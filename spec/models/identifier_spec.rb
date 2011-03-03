require File.dirname(__FILE__) + '/../spec_helper'

describe Identifier do

  it { should have_many(:publications).through(:identifyings) }
  it { should have_many(:identifyings).dependent(:destroy) }

  it "should have an id_type_string based on the class" do
    Identifier.id_type_string.should == 'Identifier'
    ISSN.id_type_string.should == "ISSN"
  end

  it "should be able to check if an identifier is valid" do
    Identifier.is_valid?('any string').should be_false
  end

  it "should be able to clean up an identifier" do
    Identifier.cleanup('any string').should == 'any string'
  end

  it "should be able to parse an identifier" do
    Identifier.parse_identifier('any string').should be_nil
  end

  context 'parsing over subclasses' do
    before(:each) do
      @isbn = '978-0-596-51617-8'
    end

    it 'should be try all subclasses to parse an identifier' do
      Identifier.subclasses.each { |id_subclass| id_subclass.should_receive(:parse_identifier).with(@isbn) }
      Identifier.parse(@isbn)
    end

    it 'should return an array, each entry of which is an array with a matching identifier subclass and the cleaned identifier' do
      Identifier.parse(@isbn).should == [[ISBN, ISBN.cleanup(@isbn)]]
    end

  end

end
