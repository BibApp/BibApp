require File.join(Rails.root, 'spec', 'spec_helper')

describe BookSection do

  it_should_behave_like "a title_primary validating work subclass", BookSection, ['Author', 'Editor'], 'Author',
                        'Editor', "http://purl.org/eprint/type/BookItem"

  describe "open_url kevs" do
    before(:each) do
      @bs = Factory.create(:book_section, :title_primary => 'Title', :publication_date_year => 2011,
                           :publication_date_month => 3, :publication_date_day => 2)
    end

    it "should always have" do
      kevs = @bs.open_url_kevs
      kevs[:format].should == "&rft_val_fmt=info%3Aofi%2Ffmt%3Akev%3Amtx%3Abook"
      kevs[:genre].should == "&rft.genre=bookitem"
      kevs[:title].should == "&rft.title=Title"
      kevs[:date].should == "&rft.date=2011-03-02"
    end

    context "with a publisher" do
      it "should have a publisher open_url kev" do
        authority = Factory.create(:publisher, :name => 'Authority')
        publisher = Factory.create(:publisher, :authority => authority)
        @bs.publisher = publisher
        @bs.open_url_kevs[:publisher].should == "&rft.pub=Authority"
      end
    end

    context "with a publication" do
      it "should have additional open_url kevs" do
        publication = Factory.create(:publication)
        publication.identifiers << ISBN.new(:name => '978-0-596-51617-8')
        @bs.publication = publication
        kevs = @bs.open_url_kevs
        kevs[:isbn].should == "&rft.isbn=978-0-596-51617-8"
      end
    end
  end

end
