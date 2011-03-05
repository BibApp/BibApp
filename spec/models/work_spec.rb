require File.dirname(__FILE__) + '/../spec_helper'

describe Work do

  it { should belong_to(:publication) }
  it { should belong_to(:publisher) }
  it { should have_many(:name_strings).through(:work_name_strings) }
  it { should have_many(:work_name_strings).dependent(:destroy) }
  it { should have_many(:people).through(:contributorships) }
  it { should have_many(:contributorships).dependent(:destroy) }
  it { should have_many(:keywords).through(:keywordings) }
  it { should have_many(:keywordings).dependent(:destroy) }
  it { should have_many(:taggings).dependent(:destroy) }
  it { should have_many(:tags).through(:taggings) }
  it { should have_many(:users).through(:taggings) }
  it { should have_many(:external_system_uris) }
  it { should have_many(:attachments) }
  it { should belong_to(:work_archive_state) }

  context "abstract and default methods" do
    it "should raise errors on subclass responsibility" do
      lambda { Work.contributor_role }.should raise_error
      lambda { Work.creator_role }.should raise_error
    end

    it "should return a default type_uri" do
      Factory.build(:abstract_work).type_uri.should be_nil
    end
  end

  context "should be able to return name information on creators" do

    def make_test_data(work_type)
      @work = Factory.create(work_type)
      @author_name_strings = 5.times.collect { Factory.create(:name_string) }
      @editor_name_strings = 5.times.collect { Factory.create(:name_string) }
      @author_name_strings.each { |ns| @work.work_name_strings.create(:role => @work.creator_role, :name_string => ns) }
      @editor_name_strings.each { |ns| @work.work_name_strings.create(:role => @work.contributor_role, :name_string => ns) }
    end

    it "returns for authors" do
      make_test_data(:generic)
      @work.authors.to_set.should == @author_name_strings.collect { |ns| {:name => ns.name, :id => ns.id} }.to_set
    end

    it "returns for editors" do
      make_test_data(:generic)
      @work.editors.to_set.should == @editor_name_strings.collect { |ns| {:name => ns.name, :id => ns.id} }.to_set
    end

    it "returns empty for editors if the author and editor roles are the same" do
      make_test_data(:patent)
      @work.editors.should == []
    end
  end

  context "should be able to return open_url kevs" do
    before(:each) do
      #to test the default implementation we need a work subclass that doesn't override open_url_kevs
      #Generic seems a safe choice, but if this test starts failing take that into consideration
      @work = Factory.create(:generic, :title_primary => 'WorkTitle', :publication_date => Date.parse('2011-03-04'),
                             :volume => '11', :issue => '9', :start_page => '211', :end_page => '310')
    end

    it "always returns a standard set" do
      kevs = @work.open_url_kevs
      kevs[:format].should == "&rft_val_fmt=info%3Aofi%2Ffmt%3Akev%3Amtx%3Ajournal"
      kevs[:genre].should == "&rft.genre=article"
      kevs[:title].should == "&rft.atitle=WorkTitle"
      kevs[:date].should == "&rft.date=2011-03-04"
      kevs[:volume].should == "&rft.volume=11"
      kevs[:issue].should == "&rft.issue=9"
      kevs[:start_page].should == "&rft.spage=211"
      kevs[:end_page].should == "&rft.epage=310"
    end

    it "with a publication returns some extra kevs" do
      authority = Factory.create(:publication, :name => 'AuthorityName')
      publication = Factory.create(:publication, :authority => authority)
      issn = Factory.create(:issn)
      publication.identifiers << issn
      @work.publication = publication
      kevs = @work.open_url_kevs
      kevs[:source].should == "&rft.jtitle=AuthorityName"
      kevs[:issn].should == "&rft.issn=#{issn.name}"
    end
  end

  context "automatic field updates and initialization" do
    it "should call initialization methods when created" do
      work = Factory.build(:work)
      [:create_work_name_strings, :create_keywords, :create_tags].each do |method|
        work.should_receive(method)
      end
      work.save
    end

    it "should call update methods when saving" do
      work = Factory.create(:work)
      work.title_primary = work.title_primary + 'make a change'
      [:update_authorities, :update_scoring_hash, :update_archive_state, :update_machine_name, :deduplicate,
       :create_contributorships].each do |method|
        work.should_receive(method)
      end
      work.save
    end

    it "should automatically update publication and pubisher information when its publication is set" do
      work = Factory.create(:work)
      publisher = Factory.create(:publisher)
      publication = Factory.create(:publication, :publisher => publisher)
      publication.authority = publication
      work.publisher_id.should be_nil
      work.publication_id.should be_nil
      work.publication = publication
      work.save
      work.publication_id.should == publication.id
      work.publisher_id.should == publisher.id
    end

    it "should update the machine name when appropriate" do
      new_title = '  New --- Title , For this'
      work = Factory.create(:work)
      work.title_primary = new_title
      work.update_machine_name
      work.machine_name.should == 'new title for this'
    end

    context "updating archive status" do
      before(:each) do
        @work = Factory.create(:work)
      end

      it "should mark itself as archived if an archive time has been recorded" do
        @work.archived?.should be_false
        @work.archived_at = Time.now
        @work.save
        @work.archived?.should be_true
      end

      it "should mark itself as ready to archive if it has attachments" do
        @work.ready_to_archive?.should be_false
        @work.title_primary = @work.title_primary + 'force a change'
        @work.should_receive(:attachments).and_return([double('attachment')])
        @work.save
        @work.ready_to_archive?.should be_true
      end

      it "should revert to initial status if it is marked ready but has not attachements" do
        @work.is_ready_to_archive
        @work.save
        @work.ready_to_archive?.should be_false
      end

    end

    it "should update its scoring hash" do
      work = Factory.create(:work)
      publication = Factory.create(:publication)
      keywords = 3.times.collect { Factory.create(:keyword) }
      name_strings = 4.times.collect { Factory.create(:name_string) }
      work.publication_date = Date.parse('2008-01-02')
      work.publication = publication
      work.keywords = keywords
      work.name_strings = name_strings
      work.save
      work.scoring_hash.should == {:year => 2008, :publication_id => publication.id,
                                   :keyword_ids => keywords.collect { |kw| kw.id },
                                   :collaborator_ids => name_strings.collect { |ns| ns.id }}
    end

    #I've had a lot of trouble with how the various models interact and with their various callbacks
    #making it difficult to assure that I'm really testing what I should be here, so I've marked the
    #tests as pending, and the set up should be regarded as provisional as well.
    context "creating contributorships" do
      before(:each) do
        #create work with exising contributorship and work_name_string/pen_name needed for another one
        @work = Factory.create(:work)
        @contributorship = Factory.create(:contributorship, :work => @work, :role => @work.creator_role)
        @work_name_string = Factory.create(:work_name_string, :work => @work, :role => @work.contributor_role)
        @pen_name = Factory.build(:pen_name, :name_string => @work_name_string.name_string)
        #we need to intercept this or the pen_name will actually create the contributorship on save and we're trying
        #to test the work side
        @pen_name.should_receive(:set_contributorships)
        @pen_name.save
      end

      it "should create any new contributorships if it is accepted" do
        pending
      end

      it "should not create new contributorships if it is not accepted" do
        pending
      end
    end
  end

  context "dupe_key checking" do
    before(:each) do
      @work = Factory.create(:generic, :title_primary => 'Work Name', :publication_date => Date.parse('2009-03-21'))
    end

    describe "title dupe key" do
      it "returns nil if it has no publication" do
        @work.title_dupe_key.should be_nil
      end

      it "returns nil if it has no publication authority" do
        @work.publication = Factory.create(:publication)
        @work.publication.should_receive(:authority).and_return(nil)
        @work.title_dupe_key.should be_nil
      end

      it "returns a solr-like string if it has a publication authority" do
        @work.publication = Factory.create(:publication)
        @work.title_dupe_key.should == ['work name', '2009', @work.publication.authority.machine_name].join("||")
      end
    end

    describe "name_string dupe key" do
      it "returns nil without any name strings" do
        @work.name_string_dupe_key.should be_nil
      end

      it "returns a solr like string with name_strings" do
        name_string = Factory.create(:name_string, :name => 'Name String Name')
        Factory.create(:work_name_string, :work => @work, :name_string => name_string)
        @work.name_strings(true).should == [name_string]
        @work.name_string_dupe_key.should == ['name string name', '2009', 'Generic', 'work name'].join('||')
      end
    end
  end
end
