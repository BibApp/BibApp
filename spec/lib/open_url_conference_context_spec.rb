require File.dirname(__FILE__) + '/../spec_helper'

describe "OpenUrlConferenceContext" do
  it "should return a valid ConferencePoster type_uri" do
      Factory.build(:conference_poster).type_uri.should ==  "http://purl.org/eprint/type/ConferencePoster"
  end
  
  it "should generate a valid openurl context" do
    #attrs = FactoryGirl.attributes_for(:conference_paper)
    
    Factory.build_stubbed(:conference_poster) do |poster|
      ns = [Factory.build_stubbed(:name_string)]      
      poster.name_strings = ns
      assert poster.open_url_context_hash
      assert poster.open_url_context_hash['aulast']
    end
  end

end