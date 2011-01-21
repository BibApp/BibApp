require File.dirname(__FILE__) + '/../spec_helper'

describe WorkNameString do

  it {should belong_to(:name_string) }
  it {should belong_to(:work)}
  it {should validate_presence_of(:name_string_id)}
  it {should validate_presence_of(:work_id)}

  describe "uniqueness validations" do

    before(:each) do
      @work_name_string = Factory.create(:work_name_string)
    end

    it {should validate_uniqueness_of(:name_string_id).scoped_to(:work_id, :role)}
    
  end

end
