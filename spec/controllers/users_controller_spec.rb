require File.dirname(__FILE__) + '/../spec_helper'

describe UsersController do

  it 'allows signup' do
    lambda do
      create_user
      response.should be_redirect
    end.should change(User, :count).by(1)
  end

  it 'signs up user with activation code' do
    create_user
    assigns(:user).reload
    assigns(:user).activation_code.should_not be_nil
  end

  it 'requires password on signup' do
    lambda do
      create_user(:password => nil)
      assigns[:user].errors.on(:password).should_not be_nil
      response.should be_success
    end.should_not change(User, :count)
  end

  it 'requires password confirmation on signup' do
    lambda do
      create_user(:password_confirmation => nil)
      assigns[:user].errors.on(:password_confirmation).should_not be_nil
      response.should be_success
    end.should_not change(User, :count)
  end

  it 'requires email on signup' do
    lambda do
      create_user(:email => nil)
      assigns[:user].errors.on(:email).should_not be_nil
      response.should be_success
    end.should_not change(User, :count)
  end


  it 'activates user' do
    user = Factory.create(:unactivated_user, :password => 'password', :password_confirmation => 'password')
    user.active?.should be_false
    get :activate, :activation_code => user.activation_code
    response.should redirect_to(login_url)
    flash[:notice].should_not be_nil
    user.reload
    user.active?.should be_true
  end

  it 'does not activate user without key' do
    get :activate
    flash[:notice].should be_nil
  end

  it 'does not activate user with blank key' do
    get :activate, :activation_code => ''
    flash[:notice].should be_nil
  end

  def create_user(options = {})
    post :create, :user => { :email => 'quire@example.com',
      :password => 'quire', :password_confirmation => 'quire' }.merge(options)
  end
end
