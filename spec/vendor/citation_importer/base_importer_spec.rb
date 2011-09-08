#This tests the citation importer plugin. It has it's own tests, but I've been doing some refactoring and
#it's not so easy to hook into its testing framework.
#Ultimately I'd prefer to either have it in the main project or as a gem.
require File.join(Rails.root, 'spec', 'spec_helper')

describe BaseImporter do

  it "should be able to parse dates" do
    importer = BaseImporter.new
    cases = {'2001-09-09' => '2001-09-09', 'pure_junk' => nil, '04-2001' => '2001-04-01',
             'something with 1 string "1988" of four digits' => '1988-01-01', 'Thursday, September 8, 2011' => '2011-09-08',
              '18/02/1977' => '1977-02-18', '02-19-1977' => '1977-02-19'}
    cases.each do |k,v|
      importer.parse_date(k).should == v
      importer.parse_date(k + 'add some junk').should == v
    end
  end

end