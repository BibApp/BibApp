RSpec.configure do |config|

  config.use_transactional_fixtures = true
  config.use_instantiated_fixtures = false
  config.fixture_path = Rails.root + '/spec/fixtures/'

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
