require File.dirname(__FILE__) + '/../spec_helper'

describe ImportsController do

  describe "protects all actions" do
    after(:each) {response.should redirect_to(new_user_session_url)}
    it "requires login for index" do
      get :index
    end

    it "requires login for new" do
      get :new
    end

    it "requires login for show" do
      get :show, :id => 1
    end

    it "requires login for create" do
      post :create
    end

    it "requires login for update" do
      put :update, :id => 1
    end
  end

  context "as a logged on user" do
    before(:each) {@user = login_as(:activated_user)}

    describe "index" do
      it "should allow viewing of index" do
        get :index
        response.should be_success
        response.should render_template(:index)
      end
    end

    describe "new" do
      it "should allow user to get view for creating new import" do
        get :new
        response.should be_success
        response.should render_template(:new)
      end
    end

    describe "create" do
      it "should allow creation of a new import" do
        pending
      end
    end

    describe "show" do
      it "should allow a user to access an existing import" do
        pending
      end
    end

    describe "update" do
      it "should allow a user to update an existing import" do
        pending
      end
    end
  end
end

