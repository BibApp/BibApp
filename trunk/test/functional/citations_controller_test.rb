require File.dirname(__FILE__) + '/../test_helper'
require 'citations_controller'

# Re-raise errors caught by the controller.
class CitationsController; def rescue_action(e) raise e end; end

class CitationsControllerTest < Test::Unit::TestCase
  def setup
    @controller = CitationsController.new
    @request    = ActionController::TestRequest.new
    @response   = ActionController::TestResponse.new
  end

  # Replace this with your real tests.
  def test_truth
    assert true
  end
end
