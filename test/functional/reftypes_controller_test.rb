require File.dirname(__FILE__) + '/../test_helper'
require 'reftypes_controller'

# Re-raise errors caught by the controller.
class ReftypesController; def rescue_action(e) raise e end; end

class ReftypesControllerTest < Test::Unit::TestCase
  fixtures :reftypes

  def setup
    @controller = ReftypesController.new
    @request    = ActionController::TestRequest.new
    @response   = ActionController::TestResponse.new
  end

  def test_truth
    assert true
  end

end
