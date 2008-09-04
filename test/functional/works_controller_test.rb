require File.dirname(__FILE__) + '/../test_helper'
require 'works_controller'

# Re-raise errors caught by the controller.
class WorksController; def rescue_action(e) raise e end; end

class WorksControllerTest < Test::Unit::TestCase
  def setup
    @controller = WorksController.new
    @request    = ActionController::TestRequest.new
    @response   = ActionController::TestResponse.new
  end

  # Replace this with your real tests.
  def test_truth
    assert true
  end
end
