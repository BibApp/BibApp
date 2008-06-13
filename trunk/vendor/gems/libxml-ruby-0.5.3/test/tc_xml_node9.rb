require "libxml"
require 'test/unit'

class TC_XML_Node9 < Test::Unit::TestCase
  def setup()
    xp = XML::Parser.new()
    str = '<root></root>'
    assert_equal(str, xp.string = str)
    @doc = xp.parse
    assert_instance_of(XML::Document, @doc)
    @root = @doc.root
  end

  def test_libxml_node_add_comment_01
    @root << XML::Node.new_comment('mycomment')
    assert_equal '<root><!--mycomment--></root>',
      @root.to_s.gsub(/\n\s*/,'')
  end

  def test_libxml_node_add_comment_02
    @root << XML::Node.new_comment('mycomment')
    assert_equal 'comment',
		@root.child.node_type_name
  end

  def test_libxml_node_add_comment_03
    @root << el = XML::Node.new_comment('mycomment')
    el << "_this_is_added"
    assert_equal '<root><!--mycomment_this_is_added--></root>',
		@root.to_s.gsub(/\n\s*/,'')
  end
end
