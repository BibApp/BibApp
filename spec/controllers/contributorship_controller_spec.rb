require File.dirname(__FILE__) + '/../spec_helper'

describe ContributorshipsController do

  before(:each) do
    @contributorship = Factory.create(:contributorship)
  end

  it "should get index" do
    get :index
    response.should be_success
    assigns(:contributorships).should_not be_nil
  end

  context "logged in" do

    before(:each) do
      login_as(:activated_user)
    end

  end
end