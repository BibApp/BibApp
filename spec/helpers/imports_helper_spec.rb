require File.dirname(__FILE__) + '/../spec_helper'

describe ImportsHelper do

  describe "Can return text describing/linking person associated with import" do

    before(:each) do
      @person = Factory.create(:person)
      @import = Factory.create(:import, :person => @person)
    end

    it "Should identify system imports" do
      @import.person = nil
      @import.save
      helper.imported_for(@import).should == 'System'
    end

    it "Should identify imports for deleted persons" do
      @person.destroy
      helper.imported_for(@import).should == 'Deleted Person'
    end

    it "Should identify and link imports for current persons" do
      link_string = helper.imported_for(@import)
      link_string.should match(Regexp.quote(person_path(@person)))
      link_string.should match(/#{@person.display_name}/)
    end

  end

end
