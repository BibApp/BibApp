require File.dirname(__FILE__) + '/../spec_helper'

describe User do

  describe 'being created' do
    before do
      @user = nil
      @creating_user = lambda do
        @user = Factory.create(:unactivated_user)
      end
    end
    
    it 'increments User#count' do
      @creating_user.should change(User, :count).by(1)
    end

    it 'initializes #activation_code' do
      @creating_user.call
      @user.reload
      @user.activation_code.should_not be_nil
    end
  end

  context 'validations' do
    before(:each) do
      @user = Factory.create(:unactivated_user)
    end

    it {should validate_presence_of(:login)}
    it {should validate_presence_of(:email)}
    it {should validate_presence_of(:password)}
    it {should validate_presence_of(:password_confirmation)}

  end

  context 'operations' do
    before(:each) do
      @user = Factory.create(:activated_user, :password => 'password', :password_confirmation => 'password')
    end

    it 'resets password' do
        @user.update_attributes(:password => 'new password', :password_confirmation => 'new password')
        User.authenticate(@user.login, 'new password').should == @user
      end

      it 'does not rehash password' do
        @user.update_attributes(:login => 'quentin2')
        User.authenticate('quentin2', 'password').should == @user
      end

      it 'authenticates user' do
        User.authenticate(@user.login, 'password').should == @user
      end

  end

end
