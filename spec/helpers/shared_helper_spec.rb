require File.dirname(__FILE__) + '/../spec_helper'

describe SharedHelper do

  before(:each) do
    @work = {}
  end

  describe "can return name string links for authors and editors" do

    def generate_namestrings(prefix, count)
      count.times.collect { |n| NameString.create(:name => "#{prefix}-#{n}").to_solr_data }
    end

    def ids(solr_namestrings)
      solr_namestrings.collect { |n| n.split('||').last }
    end

    it "should return an empty string if there are no authors" do
      @work['authors_data'] = nil
      helper.link_to_authors(@work).should == ''
    end

    it "should return an empty string if there are no editors" do
      @work['editors_data'] = nil
      helper.link_to_editors(@work).should == ''
    end

    it "should return links to all authors/editors if there are five or fewer" do
      ['author', 'editor'].each do |role|
        @work["#{role}s_data"] = generate_namestrings(role, 3)
        links = helper.send("link_to_#{role}s", @work)
        3.times do |n|
          links.should match(/#{role}-#{n}/)
        end
        ids(@work["#{role}s_data"]).each do |id|
          links.should match(Regexp.quote(name_string_path(id)))
        end
        links.should_not match(/more/)
      end
    end

    it "should return links to five authors/editors and a more link if there are more than five" do
      ['author', 'editor'].each do |role|
        @work["#{role}s_data"] = generate_namestrings(role, 6)
        @work["pk_i"] = 12
        links = helper.send("link_to_#{role}s", @work)
        5.times do |n|
          links.should match(/#{role}-#{n}/)
        end
        ids(@work["#{role}s_data"]).first(5).each do |id|
          links.should match(Regexp.quote(name_string_path(id)))
        end
        links.should_not match(/#{role}-5/)
        id = ids(@work["#{role}s_data"])[5]
        links.should_not match(Regexp.quote(name_string_path(id)))
        links.should match(/more/)
        links.should match(Regexp.quote(work_path(12)))
      end
    end

    it "should indicate that editor name strings belong to editors" do
      @work['editors_data'] = generate_namestrings('editor', 3)
      links = helper.link_to_editors(@work)
      links.should match(/\(Eds.\)/)
    end

    it "should not say 'In' if there are editors but no authors" do
      @work["editors_data"] = generate_namestrings('editor', 3)
      links = helper.link_to_editors(@work)
      links.should_not match(/In/)
    end

    it "should say 'In' if there are both editors and authors" do
      @work['editors_data'] = generate_namestrings('editor', 3)
      @work['authors_data'] = generate_namestrings('author', 3)
      links = helper.link_to_editors(@work)
      links.should match(/In/)
    end
  end

  describe "can generate links for publishers and publications" do
    it "should return unknown for blank data" do
      helper.link_to_work_publication(@work).should == t('app.unknown')
      helper.link_to_work_publisher(@work).should == t('app.unknown')
    end

    it "should return a link for a publisher with valid data" do
      @work['publisher_data'] = "PubName||12"
      link = link_to_work_publisher(@work)
      link.should match('PubName')
      link.should match(Regexp.quote(publisher_path(12)))
    end

    it "should return a link for a publication with valid data" do
      @work['publication_data'] = "PubName||13"
      link = link_to_work_publication(@work)
      link.should match('PubName')
      link.should match(Regexp.quote(publication_path(13)))
    end
  end
end
