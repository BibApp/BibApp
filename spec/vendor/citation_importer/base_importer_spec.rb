#This tests the citation importer plugin. It has it's own tests, but I've been doing some refactoring and
#it's not so easy to hook into its testing framework.
#Ultimately I'd prefer to either have it in the main project or as a gem.
require File.join(File.dirname(__FILE__), '..', '..', '..', 'spec', 'spec_helper')

describe BaseImporter do

  it "should be able to parse dates" do
    importer = BaseImporter.new
    cases = {'2001-09-09' => results(2001,9,9), 'pure_junk' => results(), '04-2001' => results(2001,4),
             'something with 1 string "1988" of four digits' => results(1988), 'Thursday, September 8, 2011' => results(2011,9,8),
              '18/02/1977' => results(1977,2,18), '02-19-1977' => results(1977,2,19), 'Mar 1999' => results(1999,3)}
    cases.each do |k,v|
      importer.publication_date_parse(k).should == v
      importer.publication_date_parse(k + 'add some junk').should == v
    end
  end

  def results(year = nil, month = nil, day = nil)
    {:publication_date_year => year, :publication_date_month => month, :publication_date_day => day}
  end
end