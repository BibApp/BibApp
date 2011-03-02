require File.join(Rails.root, 'spec', 'spec_helper')

shared_examples_for "a title_primary validating work subclass" do |subclass, roles, author_role, contributor_role, type_uri|
  before(:each) do
    @object = Factory.create(subclass.to_s.underscore)
  end

  it { should validate_presence_of(:title_primary) }

  describe "roles" do
    it "should have the right roles" do
      subclass.roles.should == roles
    end

    it "should have creator_role author" do
      subclass.creator_role.should == author_role
      roles.member?(author_role).should be_true
    end

    it "should have contributor_role author" do
      subclass.contributor_role.should == contributor_role
      roles.member?(contributor_role).should be_true
    end

    it "should have the right type_uri" do
      @object.type_uri.should == type_uri
    end

  end
end