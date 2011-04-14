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
    it { should have_one(:person)}
  end

  context 'validations' do
    before(:each) do
      @user = Factory.create(:unactivated_user)
    end

    it { should validate_presence_of(:email) }
    it { should validate_presence_of(:password) }
    it { should validate_presence_of(:password_confirmation) }

    it { should ensure_length_of(:email).is_at_least(3).is_at_most(100) }
    it { should ensure_length_of(:password).is_at_least(4).is_at_most(40) }
    it { should validate_uniqueness_of(:email) }
    [:email, :password, :password_confirmation].each do |field|
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
      @user.update_attributes(:email => 'quentin2@example.com')
      @user.valid_password?('password')
    end

    it 'authenticates user' do
      @user.valid_password?('password')
    end

    it 'can return a code for validating a new email' do
      code = @user.email_update_code('new_mail@example.com')
      code.should be_a(String)
      code.length.should == 20
    end

  end

  it "can return a list of first letters of users' emails" do
    emails = ['aaron@example.com', 'fred@example.com', 'joe@example.com', 'John@example.com', 'pete@example.com']
    emails.each do |email|
      Factory.create(:user, :email => email)
    end
    User.letters.should == ['A', 'F', 'J', 'P']
  end

  context "roles" do
    before(:each) do
      @user = Factory.create(:user)
      @work = Factory.create(:work)
    end

    it "has arbitrary roles on arbitrary objects as 'admin' of System" do
      @user.has_role 'admin', System
      @user.has_role?('admin', System).should be_true
      @user.has_role?('admin', @work).should be_true
      @user.has_role?('admin', Work)
      @user.has_role?('editor', @work).should be_true
      @user.has_role?('editor').should be_true
    end

    it "has'role' on arbitrary objects as 'role' of System" do
      @user.has_role('editor', System)
      @user.has_role?('editor').should be_true
      @user.has_role?('editor', Work).should be_true
      @user.has_role?('editor', @work).should be_true
    end

    it "has the 'editor' role on an object if it has the 'admin' role on that object" do
      @user.has_role?('editor', @work).should be_false
      @user.has_role('admin', @work)
      @user.has_role?('editor', @work).should be_true
    end

    it "has role on any group instance, then it has it on Group" do
      @user.has_role?('editor', Group).should be_false
      group = Factory.create(:group)
      @user.has_role('editor', group)
      @user.has_role?('editor', Group).should be_true
    end

    it 'has role on Group then it has it on Person' do
      @user.has_role?('editor', Person).should be_false
      @user.has_role('editor', Group)
      @user.has_role?('editor', Person).should be_true
    end

    it 'has role on any group instance then it has it on Person' do
      @user.has_role?('editor', Person).should be_false
      @user.has_role('editor', Factory.create(:group))
      @user.has_role?('editor', Person).should be_true
    end

    it 'has role on Work if it has it on Person' do
      @user.has_role?('editor', Work).should be_false
      @user.has_role('editor', Person)
      @user.has_role?('editor', Work).should be_true
    end

    it 'has role on Work if it has it on any Person' do
      @user.has_role?('editor', Work).should be_false
      @user.has_role('editor', Factory.create(:person))
      @user.has_role('editor', Work).should be_true
    end

    it "has role on Person instance if it has role on any of the instance's groups" do
      person = Factory.create(:person)
      @user.has_role?('editor', person).should be_false
      group = Factory.create(:group)
      person.groups << group
      @user.has_role('editor', group)
      @user.has_role?('editor', person).should be_true
    end

    it "has role on work instance if it has role on any of the instance's works" do
      work = Factory.create(:work)
      @user.has_role?('editor', work).should be_false
      person = Factory.create(:person)
      pen_name = Factory.create(:pen_name)
      Contributorship.create(:pen_name => pen_name, :work => work, :person => person).verify_contributorship
      work.reload
      @user.has_role('editor', person)
      @user.has_role?('editor', work).should be_true
    end

    context "explicitly checking for roles (no cascading)" do
      it "can check explicitly for roles (e.g. skip cascading)" do
        work = Factory.create(:work)
        @user.has_role('editor', Work)
        @user.has_explicit_role?('editor', work).should be_false
      end

      it "finds a role for a class if the user has it" do
        @user.has_role('editor', Work)
        @user.has_explicit_role?('editor', Work)
      end

      it "finds a role for an object if the user has it" do
        work = Factory.create(:work)
        @user.has_role('editor', work)
        @user.has_explicit_role?('editor', work)
      end

    end
  end


end
