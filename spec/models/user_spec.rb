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

  context 'associations' do
    it { should have_and_belong_to_many(:roles) }
    it { should have_many(:imports) }
    it { should have_many(:taggings).dependent(:destroy) }
    it { should have_many(:tags).through(:taggings) }
    it { should have_many(:users).through(:taggings) }
  end

  context 'validations' do
    before(:each) do
      @user = Factory.create(:unactivated_user)
    end

    it { should validate_presence_of(:login) }
    it { should validate_presence_of(:email) }
    it { should validate_presence_of(:password) }
    it { should validate_presence_of(:password_confirmation) }

    it { should ensure_length_of(:login).is_at_least(3).is_at_most(40) }
    it { should ensure_length_of(:email).is_at_least(3).is_at_most(100) }
    it { should ensure_length_of(:password).is_at_least(4).is_at_most(40) }
    it { should validate_uniqueness_of(:login) }
    it { should validate_uniqueness_of(:email) }
    [:login, :email, :password, :password_confirmation].each do |field|
      it { should allow_mass_assignment_of(field) }
    end
    [:crypted_password, :remember_token, :persistence_token, :activation_code, :activated_at].each do |field|
      it { should_not allow_mass_assignment_of(field) }
    end
  end

  context 'operations' do
    before(:each) do
      @user = Factory.create(:activated_user, :password => 'password', :password_confirmation => 'password')
    end

    it 'resets password' do
      @user.update_attributes(:password => 'new password', :password_confirmation => 'new password')
      @user.valid_password?('new_password')
    end

    it 'does not rehash password' do
      @user.update_attributes(:login => 'quentin2')
      @user.valid_password?('password')
    end

    it 'authenticates user' do
      @user.valid_password?('password')
    end

  end

  it "can return a list of first letters of users' logins" do
    logins = ['Aaron', 'Fred', 'Joe', 'John', 'Pete']
    logins.each do |login|
      Factory.create(:user, :login => login)
    end
    User.letters.collect {|u| u.letter}.should == ['A', 'F', 'J', 'P']
  end

end
