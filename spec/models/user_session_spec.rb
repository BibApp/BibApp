require File.dirname(__FILE__) + '/../spec_helper'

describe UserSession do

  before(:each) do
    activate_authlogic
    @user = Factory.create(:activated_user)
    @session = UserSession.new(@user)
  end

  it "should return nil if this is a new record" do
    @session.to_key.should be_nil
  end

  it "should return primary key if this is not a new record" do
    @session.save!
    @session.to_key.should_not be_nil
  end

end
