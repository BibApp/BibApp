require File.dirname(__FILE__) + '/../spec_helper'

describe TranslationsHelper do

  it "can translate internal bibapp roles" do
    helper.t_bibapp_role_name('Admin').should == 'Admin'
    helper.t_bibapp_role_name('ediTOR', :count => 2).should == 'Editors'
  end

  it "can translate work role names" do
    helper.t_work_role_name('Co-Principal INVESTIGATOR').should == 'Co-Principal Investigator'
    helper.t_work_role_name_pl('Committee Chair').should == 'Committee Chairs'
  end

  it "can help translate unknown names, possibly with identifiers" do
    I18n.with_locale(:de) do
      helper.name_or_unknown("joebob").should == 'joebob'
      helper.name_or_unknown('Unknown').should == 'Unbekannt'
      helper.name_or_unknown('Unknown (123-456-7890)').should == 'Unbekannt (123-456-7890)'
      helper.name_or_unknown('Unknown - a Journal').should == 'Unknown - a Journal'
    end
  end

end
