require File.dirname(__FILE__) + '/../test_helper'

class <%= class_name %>Test < Test::Unit::TestCase
  # Be sure to include AuthenticatedTestHelper in test/test_helper.rb instead.
  # Then, you can remove it from this and the functional test.
  include AuthenticatedTestHelper
  fixtures :<%= table_name %>

  def test_should_create_<%= file_name %>
    assert_difference <%= class_name %>, :count do
      assert create_<%= file_name %>.valid?
    end
  end

  def test_should_require_login
    assert_no_difference <%= class_name %>, :count do
      u = create_<%= file_name %>(:login => nil)
      assert u.errors.on(:login)
    end
  end

  def test_should_require_password
    assert_no_difference <%= class_name %>, :count do
      u = create_<%= file_name %>(:password => nil)
      assert u.errors.on(:password)
    end
  end

  def test_should_require_password_confirmation
    assert_no_difference <%= class_name %>, :count do
      u = create_<%= file_name %>(:password_confirmation => nil)
      assert u.errors.on(:password_confirmation)
    end
  end

  def test_should_require_email
    assert_no_difference <%= class_name %>, :count do
      u = create_<%= file_name %>(:email => nil)
      assert u.errors.on(:email)
    end
  end

  def test_should_reset_password
    <%= table_name %>(:quentin).update_attributes(:password => 'new password', :password_confirmation => 'new password')
    assert_equal <%= table_name %>(:quentin), <%= class_name %>.authenticate('quentin', 'new password')
  end

  def test_should_not_rehash_password
    <%= table_name %>(:quentin).update_attributes(:login => 'quentin2')
    assert_equal <%= table_name %>(:quentin), <%= class_name %>.authenticate('quentin2', 'test')
  end

  def test_should_authenticate_<%= file_name %>
    assert_equal <%= table_name %>(:quentin), <%= class_name %>.authenticate('quentin', 'test')
  end

  protected
    def create_<%= file_name %>(options = {})
      <%= class_name %>.create({ :login => 'quire', :email => 'quire@example.com', :password => 'quire', :password_confirmation => 'quire' }.merge(options))
    end
end
