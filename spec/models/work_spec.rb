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

end
