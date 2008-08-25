#initialize environment
RAILS_ENV = 'test'

require 'rubygems'
require 'test/unit'
require 'citation_parser'
require 'hpricot'
require 'htmlentities'

class CitationParserTest < Test::Unit::TestCase
  FIX_DIR = "#{File.expand_path(File.dirname(__FILE__))}/fixtures"

  def setup
    @parser = CitationParser.new
    @ris_data = File.read("#{FIX_DIR}/papers.ris")
    @bib_data = File.read("#{FIX_DIR}/papers.bib")
    @med_data = File.read("#{FIX_DIR}/papers.med")
    @rxml_deprecated_data = File.read("#{FIX_DIR}/papers.deprecated.rxml")
    @rxml_data = File.read("#{FIX_DIR}/papers.rxml")
  end

  def test_ris_parser
    citations, errorCheck = @parser.parse(@ris_data)
    assert_equal errorCheck, 1  # no errors
    assert_not_nil citations
    assert_equal citations.size, 7
    citations.each do |c|
      assert_equal :ris, c.citation_type
    end
  end
  
  def test_ris_field_types
    p = CitationParser.new
    citations = p.parse(@ris_data)
    
  end
  
#  def test_bibtex_parser
#    citations = @parser.parse(@bib_data)
#    assert_not_nil citations
#    assert_equal citations.size, 14
#    citations.each do |c|
#      assert_equal :bibtex, c.citation_type
#    end
#  end
  
  def test_medline_parser
    citations, errorCheck = @parser.parse(@med_data)
    assert_equal errorCheck, 1  # no errors
    assert_not_nil citations
    assert_equal citations.size, 7
   
    citations.each do |c|
      assert_equal :medline, c.citation_type
    end
  end
  
  def test_refworks_deprecated_xml_parser
    citations, errorCheck = @parser.parse(@rxml_deprecated_data)
    assert_equal errorCheck, 1  # no errors
    assert_not_nil citations
    assert_equal citations.size, 34
    citations.each do |c|
      assert_equal :refworks_deprecated_xml, c.citation_type
    end
  end
  
  def test_refworks_xml_parser
    citations, errorCheck = @parser.parse(@rxml_data)
    assert_equal errorCheck, 1  # no errors
    assert_not_nil citations
    assert_equal citations.size, 20
    citations.each do |c|
      assert_equal :refworks_xml, c.citation_type
    end
  end

end
