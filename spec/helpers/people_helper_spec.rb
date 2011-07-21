require File.join(File.dirname(__FILE__), '..', 'spec_helper.rb')

describe PeopleHelper do

  before(:each) do
    @ldap_hash = {:sn => 'mcrogerson', :givenname => 'ROGER', :title => "Professor", :ou => 'Mathematics'}
  end

  describe "can prettify LDAP department" do
    it 'uses both title and ou if present' do
      helper.pretty_ldap_dept(@ldap_hash).should == '(Professor, Mathematics)'
    end

    it 'uses title only if ou not present' do
      @ldap_hash.delete(:ou)
      helper.pretty_ldap_dept(@ldap_hash).should == '(Professor)'
    end

    it 'uses ou only if title not present' do
      @ldap_hash.delete(:title)
      helper.pretty_ldap_dept(@ldap_hash).should == '(Mathematics)'
    end

    it 'should be blank if neither title nor ou is present' do
      @ldap_hash.delete(:title)
      @ldap_hash.delete(:ou)
      helper.pretty_ldap_dept(@ldap_hash).should == ''
    end

  end

  describe "can prettify LDAP name" do
    it 'shows a prettified name with department information' do
      helper.pretty_ldap_person(@ldap_hash).should == 'Roger McRogerson (Professor, Mathematics)'
    end
  end

end