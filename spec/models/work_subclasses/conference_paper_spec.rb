require File.join(Rails.root, 'spec', 'spec_helper')

describe ConferencePaper do

  it_should_behave_like "a title_primary validating work subclass", ConferencePaper,
                        ['Author', 'Editor'], 'Author',
                        'Editor', "http://purl.org/eprint/type/ConferencePaper"

  describe "open_url kevs" do
    before(:each) do
      @cp = Factory.create(:conference_paper, :title_primary => 'Title', :publication_date_year => 2011,
                          :publication_date_month => 3, :publication_date_day => 2,
                          :volume => '11', :issue => '155', :start_page => '200', :end_page => '233')
    end

    it "should always have" do
      kevs = @cp.open_url_kevs
      kevs[:format].should == "&rft_val_fmt=info%3Aofi%2Ffmt%3Akev%3Amtx%3Abook"
      kevs[:genre].should == "&rft.genre=proceeding"
      kevs[:title].should == "&rft.title=Title"
      kevs[:date].should == "&rft.date=2011-03-02"
      kevs[:volume].should == "&rft.volume=11"
      kevs[:issue].should == "&rft.issue=155"
      kevs[:start_page].should == "&rft.spage=200"
      kevs[:end_page].should == "&rft.epage=233"
    end

    context "with a publication" do
      it "should have additional open_url kevs" do
        authority = Factory.create(:publication, :name => 'Authority')
        publication = Factory.create(:publication, :authority => authority)
        publication.identifiers << ISSN.new(:name => '1234-4321')
        publication.identifiers << ISBN.new(:name => '978-0-596-51617-8')
        @cp.publication = publication
        kevs = @cp.open_url_kevs
        kevs[:source].should == "&rft.jtitle=Authority"
        kevs[:issn].should == "&rft.issn=1234-4321"
        kevs[:isbn].should == "&rft.isbn=978-0-596-51617-8"
      end
    end
  end

end
