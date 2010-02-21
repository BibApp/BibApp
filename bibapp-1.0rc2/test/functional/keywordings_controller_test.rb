require File.dirname(__FILE__) + '/../test_helper'
require 'keywordings_controller'

# Re-raise errors caught by the controller.
class KeywordingsController; def rescue_action(e) raise e end; end

class KeywordingsControllerTest < Test::Unit::TestCase
  def setup
    @controller = KeywordingsController.new
    @request    = ActionController::TestRequest.new
    @response   = ActionController::TestResponse.new
  end

  def test_should_get_index
    get :index
    assert_response :success
    assert_not_nil assigns(:keywordings)
  end

  def test_should_get_new
    get :new
    assert_response :success
  end

  def test_should_create_keywording
    assert_difference('Keywording.count') do
      post :create, :keywording => { }
    end

    assert_redirected_to keywording_path(assigns(:keywording))
  end

  def test_should_show_keywording
    get :show, :id => 1
    assert_response :success
  end

  def test_should_get_edit
    get :edit, :id => 1
    assert_response :success
  end

  def test_should_update_keywording
    put :update, :id => 1, :keywording => { }
    assert_redirected_to keywording_path(assigns(:keywording))
  end

  def test_should_destroy_keywording
    assert_difference('Keywording.count', -1) do
      delete :destroy, :id => 1
    end

    assert_redirected_to keywordings_path
  end
end
