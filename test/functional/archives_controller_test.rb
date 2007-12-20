require File.dirname(__FILE__) + '/../test_helper'
require 'archives_controller'

# Re-raise errors caught by the controller.
class ArchivesController; def rescue_action(e) raise e end; end

class ArchivesControllerTest < Test::Unit::TestCase
  fixtures :citations
  
  def setup
    @controller = ArchivesController.new
    @request    = ActionController::TestRequest.new
    @response   = ActionController::TestResponse.new
    create_test_files
  end
  
  def teardown
    FileUtils.cd ARCHIVE_UPLOAD_DIR do
      FileUtils.rm %w{ 15.pdf 43.pdf 58.pdf 63.pdf }
    end  
  end

  # Replace this with your real tests.

  def create_test_files
    FileUtils.mkdir(ARCHIVE_UPLOAD_DIR) unless File.exist?(ARCHIVE_UPLOAD_DIR)
    FileUtils.mkdir(ARCHIVE_OUTPUT_DIR) unless File.exist?(ARCHIVE_OUTPUT_DIR)
    FileUtils.cd ARCHIVE_UPLOAD_DIR do 
      FileUtils.touch %w{ 15.pdf 43.pdf 58.pdf 63.pdf }
    end
  end

  def test_finds_matches
    get :create
    assert_response :success
    ready = assigns(:ready)
    assert ready.size > 0, "Ready is empty!"
    assert ready.include?(citations(:decision_support_article))
    assert ready.include?(citations(:cost_bid_article))
    assert ready.include?(citations(:quantifying_article))
    assert !ready.include?(citations(:price_control_article))
  end
  
  def test_finds_cites_without_files
    get :create
    nofile = assigns(:nofile)
    assert nofile.include?(citations(:price_control_article))
    assert !nofile.include?(citations(:quantifying_article))
  end
  
  def test_finds_files_without_cites
    get :create
    nocite = assigns(:nocite)
    assert nocite.include?('63.pdf')
    assert !nocite.include?('15.pdf')
    assert !nocite.include?('.')
  end
end
