require 'rubygems'
require 'test/unit'
require 'htmlentities'
require 'logger'


#initialize environment
RAILS_ROOT = File.dirname(__FILE__) + "/.." # fake the rails root directory.
RAILS_ENV = "test"  # fake test environment
RAILS_DEFAULT_LOGGER = Logger.new(STDERR) #fake logger (log to Standard Error)

require 'citation_parser'

class CitationParserTest < Test::Unit::TestCase
  FIX_DIR = "#{File.expand_path(File.dirname(__FILE__))}/fixtures"

  def setup
    @parser = CitationParser.new
    @ris_data = File.read("#{FIX_DIR}/papers.ris")
    @ris_unicode_data = File.read("#{FIX_DIR}/papers.unicode.ris")
    @bib_data = File.read("#{FIX_DIR}/papers.bib")
    @med_data = File.read("#{FIX_DIR}/papers.med")
    @rxml_deprecated_data = File.read("#{FIX_DIR}/papers.deprecated.rxml")
    @rxml_data = File.read("#{FIX_DIR}/papers.rxml")
    @invalid_data = File.read("#{FIX_DIR}/papers.invalid-format")
  end

  def test_ris_parser
    citations = @parser.parse(@ris_data)
    assert_not_nil citations
    assert_equal citations.size, 7
    citations.each do |c|
      assert_equal :ris, c.citation_type
      assert_not_nil c.properties[:original_data], "Missing Original Data: #{c.inspect}"
    end
  end

  def test_ris_unicode_parser
    citations = @parser.parse(@ris_unicode_data)
    assert_not_nil citations
    assert_equal citations.size, 1
    citations.each do |c|
      assert_equal :ris, c.citation_type
      assert_not_nil c.properties[:original_data], "Missing Original Data: #{c.inspect}"
      #verify it successfully parsed out non-English characters in title & author
      assert_equal c.properties[:t1], ["El carácter conservador de la opinión pública"]
      assert_equal c.properties[:a1][1], "González,L. (Trans)"
    end
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
    citations = @parser.parse(@med_data)
    assert_not_nil citations
    assert_equal citations.size, 8

    citations.each do |c|
      assert_equal :medline, c.citation_type
      assert_not_nil c.properties[:original_data], "Missing Original Data: #{c.inspect}"
    end
  end

  def test_refworks_xml_parser
    citations = @parser.parse(@rxml_data)
    assert_not_nil citations
    assert_equal citations.size, 20
    citations.each do |c|
      assert_equal :refworks_xml, c.citation_type
      assert_not_nil c.properties[:original_data], "Missing Original Data: #{c.inspect}"
    end
  end

  def test_invalid_format
    citations = @parser.parse(@invalid_data)
    assert_nil citations  #nil means we couldn't parse anything
  end
end
