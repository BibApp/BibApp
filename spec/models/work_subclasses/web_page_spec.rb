require File.join(Rails.root, 'spec', 'spec_helper')

describe WebPage do

  describe "roles" do
    it "should have the right roles" do
      WebPage.roles.should == ['Author']
    end

    it "should have creator_role author" do
      WebPage.creator_role.should == 'Author'
    end

    it "should have contributor_role author" do
      WebPage.contributor_role.should == 'Author'
    end

    it "should have the right type_uri" do
      Factory.create(:web_page).type_uri.should == "http://purl.org/dc/dcmitype/InteractiveResource"
    end
  end

end
