require File.dirname(__FILE__) + '/../spec_helper'

describe UserSessionsController do

  before(:each) do
    include Authlogic::TestCase
    activate_authlogic
  end

  context 'logged in' do
    before(:each) do
      @a_user = login_as(:activated_user, :password => 'password', :password_confirmation => 'password')
    end

    it 'destroys logged in session' do
      get :destroy
      flash[:notice].should == "Logout successful!"
      response.should redirect_to(root_url)
    end

  end

  context 'not logged in' do
    before(:each) do
      @a_user = Factory.create(:activated_user, :password => 'password', :password_confirmation => 'password')
      ensure_logged_out(@a_user)
    end

    it 'gets new' do
      get :new
      response.should render_template('new')
      response.should be_success
    end

    it 'logs in with correct password' do
      get :create, :user_session => {:email => @a_user.email, :password => 'password'}
      flash[:notice].should == "Login successful!"
      response.should redirect_to(works_url)
    end

    it 'renders new with incorrect password' do
      get :create, :user_session => {:email => @a_user.email, :password => 'not_the_password'}
      response.should render_template('new')
    end

  end

end
