require File.join(Rails.root, 'spec', 'spec_helper')

describe BookWhole do

  it_should_behave_like "a title_primary validating work subclass", BookWhole,
                        ['Author', 'Editor', 'Translator', 'Illustrator'],
                        'Author', 'Editor', "http://purl.org/eprint/type/Book"

  describe "open_url kevs" do
    before(:each) do
      authority = Factory.create(:publisher, :name => 'Authority')
      publisher = Factory.create(:publisher, :authority => authority)
      @b = Factory.create(:book_whole, :title_primary => 'Title', :publication_date_year => 2011,
                          :publication_date_month => 3, :publication_date_day => 2,
                          :publisher => publisher)
    end

    it "should always have" do
      kevs = @b.open_url_kevs
      kevs[:format].should == "&rft_val_fmt=info%3Aofi%2Ffmt%3Akev%3Amtx%3Abook"
      kevs[:genre].should == "&rft.genre=book"
      kevs[:title].should == "&rft.btitle=Title"
      kevs[:date].should == "&rft.date=2011-03-02"
      kevs[:publisher].should == "&rft.pub=Authority"
    end

    context "with a publication" do
      it "should have isbn open_url kevs" do
        authority = Factory.create(:publication, :name => 'Authority')
        publication = Factory.create(:publication, :authority => authority)
        publication.identifiers << ISBN.new(:name => '978-0-596-51617-8')
        @b.publication = publication
        kevs = @b.open_url_kevs
        kevs[:isbn].should == "&rft.isbn=978-0-596-51617-8"
      end
    end
  end

end
