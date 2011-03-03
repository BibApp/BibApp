require File.dirname(__FILE__) + '/../spec_helper'

describe WorkNameString do

  it { should belong_to(:name_string) }
  it { should belong_to(:work) }
  it { should validate_presence_of(:name_string_id) }
  it { should validate_presence_of(:work_id) }

  describe "uniqueness validations" do

    before(:each) do
      @work_name_string = Factory.create(:work_name_string)
    end

    it { should validate_uniqueness_of(:name_string_id).scoped_to(:work_id, :role) }

  end

  it "can represent itself for solr" do
    ns = Factory.create(:name_string, :name => 'Name')
    wns = Factory.create(:work_name_string, :name_string => ns, :role => 'role')
    wns.to_solr_data.should == ['Name', wns.name_string.id, wns.position, 'role'].join('||')
  end

  describe "batch creation" do
    before(:each) do
      @works = (1..5).collect { Factory.create(:work) }
      @name_string = Factory.create(:name_string)
    end

    it "creates from a name_string and a list of works" do
      WorkNameString.create_batch_from_works!(@name_string, @works)
      @works.each do |w|
        WorkNameString.where(:name_string_id => @name_string.id, :work_id => w).should_not be_nil
      end
    end

    it "creates from a name_string and work_data suitable for Work#import_batch!" do
      work_data = 'dummy work data'
      Work.should_receive(:import_batch!).with(work_data).and_return(@works)
      WorkNameString.should_receive(:create_batch_from_works!).with(@name_string, @works)
      WorkNameString.create_batch!(@name_string, work_data).should == @works
    end

  end


end