require File.dirname(__FILE__) + '/../test_helper'
require 'authorships_controller'

# Re-raise errors caught by the controller.
class AuthorshipsController; def rescue_action(e) raise e end; end

class AuthorshipsControllerTest < Test::Unit::TestCase
  def setup
    @controller = AuthorshipsController.new
    @request    = ActionController::TestRequest.new
    @response   = ActionController::TestResponse.new
  end

  # Replace this with your real tests.
  def test_truth
    assert true
  end
end
