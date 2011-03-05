require File.dirname(__FILE__) + '/../spec_helper'

describe PenName do

  it {should belong_to(:name_string)}
  it {should belong_to(:person)}
  it {should have_many(:contributorships).dependent(:destroy)}
  it {should have_many(:works).through(:contributorships)}

  it {should validate_presence_of(:name_string_id)}
  it {should validate_presence_of(:person_id)}

  it "should be able to index its works" do
    pen_name = Factory.create(:pen_name)
    person = Factory.create(:person)
    work = Factory.create(:work)
    Contributorship.create(:person => person, :work => work, :pen_name => pen_name)
    pen_name.works(true).each {|w| w.should_receive(:set_for_index_and_save)}
    Index.should_receive(:batch_index)
    pen_name.index_works
  end

  it "should be able to set contributorships" do
    pen_name = Factory.create(:pen_name)
    pen_name.name_string = Factory.create(:name_string)
    5.times do
      pen_name.name_string.work_name_strings << Factory.build(:work_name_string, :role => 'Author')
    end
    works_to_add = pen_name.name_string.work_name_strings.collect {|wns| wns.work}
    works_to_add.first.is_duplicate
    pen_name.contributorships.should be_empty
    pen_name.set_contributorships
    works_to_add.each do |w|
      pen_name.contributorships.where(:work_id => w.id, :person_id => pen_name.person.id,
                                      :role => 'Author').exists?.should == w.accepted?
    end
  end

end
