#!/usr/bin/env ruby

require 'test/unit'
require 'hpricot'
require 'load_files'

class TestParser < Test::Unit::TestCase
  # normally, the link tags are empty HTML tags.
  # contributed by laudney.
  def test_normally_empty
    doc = Hpricot::XML("<rss><channel><title>this is title</title><link>http://fake.com</link></channel></rss>")
    assert_equal "this is title", (doc/:rss/:channel/:title).text
    assert_equal "http://fake.com", (doc/:rss/:channel/:link).text
  end

  # make sure XML doesn't get downcased
  def test_casing
    doc = Hpricot::XML(TestFiles::WHY)
    assert_equal "hourly", (doc.at "sy:updatePeriod").inner_html
    assert_equal 1, (doc/"guid[@isPermaLink]").length
  end

  # be sure tags named "text" are ok
  def test_text_tags
    doc = Hpricot::XML("<feed><title>City Poisoned</title><text>Rita Lee has poisoned Brazil.</text></feed>")
    assert_equal "City Poisoned", (doc/"title").text
  end
end
