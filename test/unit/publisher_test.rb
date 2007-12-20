require File.dirname(__FILE__) + '/../test_helper'

class PublisherTest < Test::Unit::TestCase
  fixtures :publishers

  # Sherpa published an API. Everything changed.
  def test_truth
    assert true
  end
end
