# This file is copied to spec/ when you run 'rails generate rspec:install'
ENV["RAILS_ENV"] ||= 'test'
require File.expand_path("../../config/environment", __FILE__)
require 'rspec/rails'
require 'shoulda'
require 'authlogic/test_case'

# Requires supporting ruby files with custom matchers and macros, etc,
# in spec/support/ and its subdirectories.
Dir[Rails.root.join("spec/support/**/*.rb")].each { |f| require f }
Dir[Rails.root.join("spec/factories/**/*.rb")].each { |f| require f }

ActionMailer::Base.delivery_method = :test

RSpec.configure do |config|

  config.use_transactional_fixtures = true
  config.use_instantiated_fixtures = false
  config.fixture_path = RAILS_ROOT + '/spec/fixtures/'

  config.mock_with :rspec

  include Authlogic::TestCase

  def login_as(factory = :activated_user, opts = {})
    activate_authlogic
    user = Factory.create(factory, opts)
    UserSession.create!(user)
    user
  end

  def ensure_logged_out(user)
    activate_authlogic
    if session = UserSession.find(user)
      session.destroy
    end
  end

end
