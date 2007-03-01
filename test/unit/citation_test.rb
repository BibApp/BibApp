require File.dirname(__FILE__) + '/../test_helper'

class CitationTest < Test::Unit::TestCase
  fixtures :citations
  
  def setup
    filter_all
  end

  # Replace this with your real tests.
  
  def test_issn_dupe_key
    c1 = citations(:decision_support_article)
    assert c1.save
    assert_not_nil c1.issn_dupe_key
    assert_equal c1.issn_dupe_key, c1[:issn_dupe_key]
    
    # this one lacks an ISSN
    c2 = citations(:price_control_article)
    assert_nil c2.issn_dupe_key
    c2.save
    c2.reload
    assert_nil c2[:issn_dupe_key]
  end
  
  def test_title_dupe_key
    c1 = citations(:decision_support_article)
    c1.save
    c1.reload
    assert_equal c1.title_dupe_key, c1[:title_dupe_key]
  end
  
  def test_title_duplicates
    c1 = citations(:price_control_article)
    dupes = c1.duplicates
    assert_citations_include(dupes, c1)
    assert_citations_include(dupes, citations(:add_pc_dupe_title))
    assert_citations_include(dupes, citations(:add_pc_dupe_title_nonunique))
    assert_citations_not_include(dupes, citations(:pc_dupe_title))
  end
  
  def test_issn_duplicates
    c1 = citations(:quantifying_article)
    dupes = c1.duplicates
    assert_citations_include(dupes, c1)
    assert_citations_include(dupes, citations(:add_quant_dupe_issn))
  end

  def test_filter_all
    c1 = citations(:decision_support_article)
    assert_not_nil(c1[:issn_dupe_key])
  end

  def test_add_unique_nonduplicates_should_return_all_passed_items
    to_add = Array.new
    to_add << citations(:add_fm_article)
    to_add << citations(:add_unc_article)
    to_add << citations(:add_nuke_article)
    
    new_list = Citation.deduplicate(to_add)
    to_add.each do |cite|
      assert_citations_include(new_list, cite)
    end
    assert_citations_accepted(new_list)
    assert_equal to_add.length, new_list.length
  end
  
  def test_add_nonunique_nonduplicates_should_return_trimmed_passed_items
    to_add = Array.new
    to_add << citations(:add_fm_article)
    to_add << citations(:add_unc_article)
    to_add << citations(:add_unc_article_nonunique)
    
    new_list = Citation.deduplicate(to_add)
    assert_citations_include(new_list, citations(:add_fm_article))
    assert_citations_include(new_list, citations(:add_unc_article))
    assert_citations_accepted(new_list)
    assert_citations_not_include(new_list, citations(:add_unc_article_nonunique))
  end
  
  def test_add_unique_duplicates_should_return_existing_items
    to_add = [
      citations(:add_pc_dupe_title),
      citations(:add_quant_dupe_issn)
    ]
    
    new_list = Citation.deduplicate(to_add)
    assert_citations_not_include(new_list, citations(:add_pc_dupe_title))
    assert_citations_not_include(new_list, citations(:add_quant_dupe_issn))
    assert_citations_include(new_list, citations(:price_control_article))
    assert_citations_include(new_list, citations(:quantifying_article))
    assert_citations_accepted(new_list)
    assert_equal to_add.length, new_list.length, "Added unique dupes, should have gotten same list!"
  end
  
  def test_add_nonunique_duplicates_should_return_trimmed_existing_items
    to_add = [
      citations(:add_pc_dupe_title),
      citations(:add_pc_dupe_title_nonunique)
    ]
    
    new_list = Citation.deduplicate(to_add)
    assert_citations_not_include(new_list, citations(:add_pc_dupe_title))
    assert_citations_not_include(new_list, citations(:add_pc_dupe_title_nonunique))
    assert_citations_include(new_list, citations(:price_control_article))
    assert_citations_accepted(new_list)
    assert_not_equal to_add.length, new_list.length, "Added nonunique dupes, new list should be shorter"
  end

  def test_import_from_file
    filename = paper_filename("rxml")
    cites = Citation.import_batch!(filename)
    assert_equal 31, cites.size
  end

  def test_bulk_import_ris
    assert_imports("ris", 7) # Contains 1 duplicate and 1 invalid record
  end
  
  def test_bulk_import_bibtex
    assert_imports("bib", 12) # contains 1 duplicate and 2 invalid recs
  end
  
  def test_bulk_import_medline
    assert_imports("med", 7) 
  end
  
  def test_bulk_import_refworks_xml
    assert_imports("rxml", 31)
  end
  
  def assert_imports(type, count) 
    data = read_papers_file(type)
    assert_not_nil data, "Couldn't read data file for #{type}"
    imported = Citation.import_batch!(data)
    assert_equal count, imported.size
  end
  
  def test_lazy_tagging
    pc_art = citations(:price_control_article)
    pc_dupe = citations(:pc_dupe_title)
    assert !pc_art.needs_retagging? # Keywords haven't changed
    pc_art.keywords = "foo"
    assert pc_art.needs_retagging? # Now they have
    pc_dupe.keywords = "foo"
    assert !pc_dupe.needs_retagging? # Don't tag duplicates, though
  end
  
  private
  
  def filter_all
    cites = Citation.find(:all)
    cites.each do |c|
      c.save
    end
  end
  
  def assert_citations_include(list, citation)
    assert list.include?(citation), "Returned list DOES NOT contain #{citation.id}: #{citation.title_primary}"
  end
  
  def assert_citations_not_include(list, citation)
    assert !list.include?(citation), "Returned contains #{citation.id}: #{citation.title_primary}"
  end
  
  def assert_citations_accepted(list)
    list.each do |cite|
      assert_equal cite.citation_state_id, 3
    end
  end
  
  def read_papers_file(type)
    File.read(paper_filename(type))
  end
  
  def paper_filename(type)
    return "test/fixtures/papers.#{type.to_s}"
  end
end
