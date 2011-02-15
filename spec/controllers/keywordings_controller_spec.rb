require File.dirname(__FILE__) + '/../spec_helper'

describe KeywordingsController do

  before(:each) do
    @keywording = Factory.create(:keywording)
  end

  it "should get index" do
    get :index
    response.should be_success
    assigns(:keywordings).should_not be_nil
  end

  it "should get show" do
    get :show, :id => @keywording.id
    response.should be_success
  end

  context "logged in" do
    before(:each) do
      @user = login_as(:activated_user)
    end

    it "should get new" do
      get :new
      response.should be_success
    end

    it "should create" do
      keyword = Factory.create(:keyword)
      lambda {
        post :create, :keywording => {:keyword_id => keyword.id, :work_id => @keywording.work.id}
      }.should change(Keywording, :count).by(1)
      response.should redirect_to(keywording_url(assigns(:keywording)))
    end

    it "should get edit" do
      @user.has_role 'editor', Work
      get :edit, :id => @keywording.id
      response.should be_success
    end

    it "should update"  do
      put :update, :id => @keywording.id, :keywording => {}
      response.should redirect_to(keywording_url(:id => @keywording.id))
    end

    it "should destroy" do
      @user.has_role 'admin', Work
      lambda {
        delete :destroy, :id => @keywording.id
      }.should change(Keywording, :count).by(-1)
      response.should redirect_to(keywordings_url)
    end
  end
end