#! /usr/bin/env ruby
$:.unshift File.join(File.dirname(__FILE__),'..','lib')

require 'test/unit'
require 'citeproc'


class TestBibo < Test::Unit::TestCase
  # Sets up a document with a range of relational and literal properties
  def setup
    @model = Bibo::BiboUtils::from_rdf('file:test/fixtures/bibo_test_data.n3', 'turtle')
  end
	
  
  # Test the basic document properties
  def test_model
    assert_not_nil(@model)
  end

end
