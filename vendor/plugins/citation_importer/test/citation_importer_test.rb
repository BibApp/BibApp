require 'test/unit'
require 'citation_importer'
require 'yaml'
require "#{File.expand_path(File.dirname(__FILE__))}/../../citation_parser/lib/citation_parser"


class CitationImporterTest < Test::Unit::TestCase
  FIX_DIR = "#{File.expand_path(File.dirname(__FILE__))}/fixtures"
  
  def setup
    @importer = CitationImporter.new
    @ris_cites = YAML::load(File.read("#{FIX_DIR}/papers.ris.yml"))
    @ris_cites_bad_date = YAML::load(File.read("#{FIX_DIR}/bad-date-papers.ris.yml"))
    #@bib_cites = YAML::load(File.read("#{FIX_DIR}/papers.bib.yml"))
    @med_cites = YAML::load(File.read("#{FIX_DIR}/papers.med.yml"))
    @med_cites_bad_date = YAML::load(File.read("#{FIX_DIR}/bad-date-papers.med.yml"))
    @refworks_deprecated_xml_cites = YAML::load(File.read("#{FIX_DIR}/papers.deprecated.rxml.yml"))
    @refworks_xml_cites = YAML::load(File.read("#{FIX_DIR}/papers.rxml.yml"))
  end

  def test_importer_classes
    imps = @importer.imps
    assert_not_nil imps
    assert_equal 4, imps.size
    imps.each do |keys, imp|
      assert CitationImporter.importers.include?( imp.class )
    end
  end

  def test_ris_hash_generation
    assert_not_nil @ris_cites
    assert_equal Array, @ris_cites.class
    hashes = @importer.citation_attribute_hashes(@ris_cites)
    assert_equal 7, hashes.size
  end
  
  def test_ris_fields
    hashes = @importer.citation_attribute_hashes(@ris_cites)
    hashes.each do |h|
      assert_not_nil h[:title_primary], "Missing Title Primary: #{h.inspect}"
      assert_not_nil h[:work_name_strings], "Missing Authors: #{h.inspect}"
      assert_not_nil h[:publication_date], "Missing Publication Date: #{h.inspect}"
    end
  end
  
  #Test that dates from RIS are parsed (or not parsed) properly
  def test_ris_dates
    hashes = @importer.citation_attribute_hashes(@ris_cites_bad_date)
    assert_equal 2, hashes.size
    
    #First citation has a valid RIS date ("2004///Spring"), which Ruby normally doesn't handle
    h = hashes.first
    assert_equal "2004", h[:publication_date]
    
    #Second citation has invalid date in the date field
    h = hashes.fetch(1)
    assert_nil h[:publication_date]
  end
  
#  def test_bib_hash_generation
#    hashes = @importer.citation_attribute_hashes(@bib_cites)
#    assert_equal 12, hashes.size
#  end
#  
#  def test_bib_fields
#    hashes = @importer.citation_attribute_hashes(@bib_cites)
#    hashes.each do |h|
#      assert_not_nil h[:title_primary], "Missing Title Primary: #{h.inspect}"
#      assert_not_nil h[:authors], "Missing Authors: #{h.inspect}"
#    end
#  end
  
  def test_med_hash_generation
    hashes = @importer.citation_attribute_hashes(@med_cites)
    assert_equal 7, hashes.size
  end
  
  def test_med_fields
    hashes = @importer.citation_attribute_hashes(@med_cites)
    hashes.each do |h|
      assert_not_nil h[:title_primary], "Missing Title Primary: #{h.inspect}"
      assert_not_nil h[:work_name_strings], "Missing Authors (work_name_strings): #{h.inspect}"
      assert_not_nil h[:publication_date], "Missing Publication Date: #{h.inspect}"
    end
  end
   
  #Test that dates from Medline are parsed (or not parsed) properly
  def test_med_dates
    hashes = @importer.citation_attribute_hashes(@med_cites_bad_date)
    assert_equal 2, hashes.size
    
    #First citation has approximate date ("Fall 2007") instead of actual date
    h = hashes.first
    assert_equal "2007", h[:publication_date]
    
    #Second citation has invalid date in the date field
    h = hashes.fetch(1)
    assert_nil h[:publication_date]
  end
  
  
  def test_refworks_xml_hash_generation
    hashes = @importer.citation_attribute_hashes(@refworks_xml_cites)
    assert_equal 20, hashes.size
  end
  
  def test_refworks_xml_fields
    hashes = @importer.citation_attribute_hashes(@refworks_xml_cites)
    hashes.each do |h|
      assert_not_nil h[:title_primary], "Missing Title Primary: #{h.inspect}"
      assert_not_nil h[:work_name_strings], "Missing Authors (work_name_strings): #{h.inspect}"
      assert_not_nil h[:publication_date], "Missing Publication Date: #{h.inspect}"
    end
  end
  
  def test_refworks_deprecated_xml_hash_generation
    hashes = @importer.citation_attribute_hashes(@refworks_deprecated_xml_cites)
    assert_equal 34, hashes.size
  end
  
  def test_refworks_deprecated_xml_fields
    hashes = @importer.citation_attribute_hashes(@refworks_deprecated_xml_cites)
    hashes.each do |h|
      assert_not_nil h[:title_primary], "Missing Title Primary: #{h.inspect}"
      assert_not_nil h[:work_name_strings], "Missing Authors (work_name_strings): #{h.inspect}"
      assert_not_nil h[:publication_date], "Missing Publication Date: #{h.inspect}"
    end
  end
  
  def test_ris_importer_finding
    assert_equal RisImporter, @importer.importer_obj(:ris).class
    @ris_cites.each do |c|
      assert_equal RisImporter, @importer.importer_obj(c.citation_type).class
    end
  end
  
  
end
