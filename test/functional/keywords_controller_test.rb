require File.dirname(__FILE__) + '/../test_helper'
require 'keywords_controller'

# Re-raise errors caught by the controller.
class KeywordsController; def rescue_action(e) raise e end; end

class KeywordsControllerTest < Test::Unit::TestCase
  def setup
    @controller = KeywordsController.new
    @request    = ActionController::TestRequest.new
    @response   = ActionController::TestResponse.new
  end

  # Replace this with your real tests.
  def test_truth
    assert true
  end
end
