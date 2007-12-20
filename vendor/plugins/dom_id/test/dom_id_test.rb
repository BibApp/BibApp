require File.expand_path(File.dirname(__FILE__) + "/test_helper")

class DomIdTest < Test::Unit::TestCase
  fixtures :things, :people_things

  def test_dom_id
    thing = Thing.find :first
    assert_equal 'thing_1', thing.dom_id
  end

  def test_people_thing
    pt = PeopleThing.find :first
    assert_equal 'people_thing_1', pt.dom_id
    
    assert_equal 'many_people_thing_1', pt.dom_id('many')
  end
  
  def test_new
    pt = PeopleThing.new
    assert_equal 'people_thing_new', pt.dom_id
    assert_equal 'many_people_thing_new', pt.dom_id('many')
  end
  
end
