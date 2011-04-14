require File.dirname(__FILE__) + '/../spec_helper'

describe Person do

  describe "fields" do
    it { should have_db_column(:user_id) }
  end

  describe "associations" do
    it { should belong_to(:user) }
    it { should have_many(:pen_names).dependent(:destroy)}
    it {should have_many(:name_strings).through(:pen_names)}
    it {should have_many(:memberships).dependent(:destroy)}
    it {should have_many(:groups).through(:memberships)}
    it {should have_many(:contributorships).dependent(:destroy)}
    it {should have_many(:works).through(:contributorships)}
    it {should have_one(:image).dependent(:destroy)}
    it {should belong_to(:user)}
  end

  describe "validations" do
    it {should validate_presence_of(:uid)}
  end

  describe "name construction methods and related" do
    before(:each) do
      @person = Person.new(:first_name => 'Joseph', :middle_name => 'Allen', :last_name => 'Peters')
    end

    it "can construct a full name" do
      @person.full_name.should == "Joseph Allen Peters"
      @person.middle_name = ''
      @person.full_name.should == 'Joseph Peters'
      @person.first_name = ''
      @person.full_name.should == 'Peters'
    end

    it "can construct a first and last name" do
      @person.first_last.should == 'Joseph Peters'
      @person.first_name = ''
      @person.first_last.should == 'Peters'
    end

    it "should return the same thing for name as first_last" do
      @person.first_last.should == @person.name
    end

    it "can construct a last and first name string" do
      @person.last_first.should == 'Peters, Joseph'
      @person.first_name = ''
      @person.last_first.should == 'Peters'
    end

    it "can construct a last first middle name string" do
      @person.last_first_middle.should == 'Peters, Joseph Allen'
      @person.middle_name = ''
      @person.last_first_middle.should == 'Peters, Joseph'
      @person.first_name = ''
      @person.last_first_middle.should == 'Peters'
    end

    it "can convert itself to a parameter" do
      @person.save
      id = @person.id
      @person.to_param.should == "#{id}-Joseph_Peters"
    end

    it "can return a list of first letters of last names over all Persons" do
      Person.destroy_all
      ['Adams', 'Rogers', 'Mendoza', 'Richards'].each do |name|
        Factory.create(:person, :last_name => name)
      end
      Person.letters.should == ['A', 'M', 'R']
    end
    
  end

  describe "finding related objects" do
    before(:each) do
      @person = Factory.create(:person)
    end

    it "can return its most recent work" do
      @person = Factory.create(:person)
      @person.most_recent_work.should be_nil
      works = 5.times.collect do
        Factory.create(:work).tap do |work|
          contributorship = Factory.create(:contributorship, :work => work, :person => @person)
          contributorship.verify_contributorship
        end
      end
      work = works.third
      work.touch
      @person.most_recent_work.should == work
    end

    it "can find all groups in which the person is not" do
      @person.groups = 3.times.collect {Factory.create(:group)}
      other_groups = 10.times.collect {Factory.create(:group)}
      @person.groups_not.to_set.should == other_groups.to_set
    end

    it "can find name strings like the person's last name but which the person does not have" do
      @person.name_strings.should_not be_empty
      other_name_strings = ('aa'..'af').collect {|letter| Factory.create(:name_string, :name => "#{@person.last_name}, #{letter}")}
      @person.name_strings_not.to_set.should == other_name_strings.to_set
    end

  end

  it "can sort an array of persons by the time of their most recent work" do
    none, old, new = 3.times.collect {Factory.create(:person)}
    old.contributorships << Factory.create(:contributorship, :work => Factory.create(:work), :person => old)
    sleep 1
    new.contributorships << Factory.create(:contributorship, :work => Factory.create(:work), :person => new)
    (old.contributorships + new.contributorships).each {|c| c.verify_contributorship}
    unordered = [old, none, new]
    Person.sort_by_most_recent_work(unordered).should == [new, old, none]
  end

  describe "solr interaction" do
    before(:each) do
      @person = Factory.create(:person, :last_name => 'Peters', :research_focus => 'focus')
      @id = @person.id
    end

    it "can return a solr filter" do
      @person.solr_filter.should == "person_id:\"#{@id}\""
    end

    it "can return conversion of person to solr data" do
      @person.should_receive(:group_ids).and_return([2,4,3])
      @person.to_solr_data.should == "Peters||#{@id}||man.jpg||2,4,3||true||#{@person.person_research_focus}"
    end

    it "can parse solr data" do
      group = Factory.create(:group)
      @person.groups << group
      solr_string = @person.to_solr_data
      last_name, id, image_url, group_ids, is_active, research_focus = Person.parse_solr_data(solr_string)
      last_name.should == 'Peters'
      id.should == @person.id
      image_url.should == @person.image_url
      group_ids.should == [group.id]
      is_active.should == 'true'
      research_focus.should == @person.person_research_focus
    end
  end

  it "can return a string indicating whether a person is active" do
    person = Person.new
    [true, false].each do |val|
      person.active = val
      person.person_active.should == val.to_s
    end
  end

  it "can return a comma separated list of its group ids" do
    person = Person.new
    person.should_receive(:group_ids).and_return([2,4,3])
    person.comma_separated_group_ids.should == '2,4,3'
  end

end