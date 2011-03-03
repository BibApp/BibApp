require File.dirname(__FILE__) + '/../spec_helper'

describe System do

  before(:each) do
    @editor = Factory.create(:user)
    @admin = Factory.create(:user)
    @editor.has_role('editor', System)
    @admin.has_role('admin', System)
    @editor.has_role('role', System)
    @admin.has_role('role', System)
  end

  it 'can give a list of administrators' do
    System.has_admins.should == [@admin]
  end

  it 'can tell if there are any administrators' do
    System.has_admins?.should be_true
    @admin.has_no_role('admin', System)
    System.has_admins?.should be_false
  end

  it 'can give a list of editors' do
    System.has_editors.should == [@editor]
  end

  it 'can tell if there are any editors' do
    System.has_editors?.should be_true
    @editor.has_no_role('editor', System)
    System.has_editors?.should be_false
  end

  it 'can look up the users for an arbitrary role' do
    System.has_role('no_role').should be_nil
    System.has_role('role').to_set.should == [@admin, @editor].to_set
  end

end
