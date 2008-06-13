# $Id: tc_xml_parser2.rb 260 2008-02-01 20:56:58Z transami $
require "libxml"
require 'test/unit'

class TC_XML_Parser2 < Test::Unit::TestCase
  def setup()
    @xp = XML::Parser.new()
  end

  def teardown()
    @xp = nil
  end

  def test_ruby_xml_parser_new()
    assert_instance_of(XML::Parser, @xp)
  end
end # TC_XML_Document
