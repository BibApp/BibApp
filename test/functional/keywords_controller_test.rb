require File.dirname(__FILE__) + '/../test_helper'
require 'keywords_controller'

# Re-raise errors caught by the controller.
class KeywordsController; def rescue_action(e) raise e end; end

class KeywordsControllerTest < ActionController::TestCase
  def setup
    @controller = KeywordsController.new
    @request    = ActionController::TestRequest.new
    @response   = ActionController::TestResponse.new
  end

  def test_should_get_index
    get :index
    assert_response :success
    assert_not_nil assigns(:keywords)
  end

  def test_should_get_new
    get :new
    assert_response :success
  end

  def test_should_create_keyword
    assert_difference('Keyword.count') do
      post :create, :keyword => { }
    end

    assert_redirected_to keyword_path(assigns(:keyword))
  end

  def test_should_show_keyword
    get :show, :id => 1
    assert_response :success
  end

  def test_should_get_edit
    get :edit, :id => 1
    assert_response :success
  end

  def test_should_update_keyword
    put :update, :id => 1, :keyword => { }
    assert_redirected_to keyword_path(assigns(:keyword))
  end

  def test_should_destroy_keyword
    assert_difference('Keyword.count', -1) do
      delete :destroy, :id => 1
    end

    assert_redirected_to keywords_path
  end
end
