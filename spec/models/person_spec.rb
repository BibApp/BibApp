require File.dirname(__FILE__) + '/../spec_helper'

describe Person do

  describe "fields" do
    it {should have_db_column(:user_id)}
  end

  describe "associations" do
    it {should belong_to(:user)}
  end
  
end