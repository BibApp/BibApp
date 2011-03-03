require File.dirname(__FILE__) + '/../spec_helper'

describe NameString do

  it {should have_many(:work_name_strings).dependent(:destroy)}
  it {should have_many(:works).through(:work_name_strings)}
  it {should have_many(:pen_names)}
  it {should have_many(:people).through(:pen_names)}

  it "can return a list of unique first letters of instance's names" do
    ['Zee', 'Alpha', 'Joe'].each {|name| Factory.create(:name_string, :name => name)}
    NameString.letters.should == ['A', 'J', 'Z']
  end

  it "can parse solr data" do
    name, id = NameString.parse_solr_data("name||id")
    name.should == 'name'
    id.should == 'id'
  end

  it "can convert to solr data" do
    name_string = Factory.create(:name_string, :name => "pete")
    name_string.to_solr_data.should == "pete||#{name_string.id}"
  end

  it "can extract a last name" do
    name_string = Factory.create(:name_string, :name => "Peterson, Peter P.")
    name_string.last_name.should == 'Peterson'
  end

  it "overrides to_param" do
    name_string = Factory.create(:name_string, :name => "Peterson-Peters, Peter P.")
    name_string.to_param.should == "#{name_string.id}-Peterson_PetersPeterP"
  end

end
