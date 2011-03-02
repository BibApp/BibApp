require File.dirname(__FILE__) + '/../spec_helper'

describe ContributorshipsController do

  before(:each) do
    @contributorship = Factory.create(:contributorship)
  end

  context "index" do
    it "should get given a person_id" do
      person = Factory.create(:person)
      get :index, :person_id => person.id
      response.should be_success
      assigns(:contributorships).should_not be_nil
    end

    it "should redirect to 404 not given a person_id" do
      get :index
      response.status.should == 404
    end
  end

  context "logged in" do

  end
end