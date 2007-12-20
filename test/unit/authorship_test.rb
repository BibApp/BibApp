require File.dirname(__FILE__) + '/../test_helper'

class AuthorshipTest < Test::Unit::TestCase
  fixtures :authorships, :people, :citations

  def test_truth
    assert true
  end
  
  def test_bulk_add_ris
    author = people(:vanveen)
    assert_bulk_add(author, "ris", 7)
  end

  def test_bulk_add_bibtex
    author = people(:vanveen)
    assert_bulk_add(author, "bib", 12)
  end

  def test_bulk_add_medline
    author = people(:vanveen)
    assert_bulk_add(author, "med", 7)
  end

  def test_bulk_add_refworks_xml
    author = people(:vanveen)
    assert_bulk_add(author, "rxml", 31)
  end

  def test_cannot_add_duplicate_authorships
    vanveen = people(:vanveen)
    cost_bid = citations(:cost_bid_article)
    
    auth = Authorship.new
    auth.person_id = vanveen.id
    auth.citation_id = cost_bid.id
    
    assert_valid auth
    auth.save
    
    auth = Authorship.new
    auth.person_id = vanveen.id
    auth.citation_id = cost_bid.id
    assert !auth.valid?
  end
  
  def test_vanveen_coauthorships
    vanveen = people(:vanveen)
    coauths = Authorship.coauthors_of(vanveen)
    assert coauths.include?(people(:hagness)), "Hagness should be a coauthor of vanveen"
    assert !coauths.include?(people(:ramanathan)), "Ramathan should not be a coauthor of vanveen"
    assert !coauths.include?(vanveen)
  end
  
  def assert_bulk_add(author, type, add_count)
    start_count = author.authorships.size
    data = read_papers_file(type)
    Authorship.create_batch!(author, data)
    assert_equal start_count+add_count, author.authorships.size
    
  end
  
  def read_papers_file(type)
    File.read("test/fixtures/papers.#{type}")
  end
  
end
