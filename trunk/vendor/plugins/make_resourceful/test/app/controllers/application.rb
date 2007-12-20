# Filters added to this controller apply to all controllers in the application.
# Likewise, all the methods added will be available for all controllers.

class ApplicationController < ActionController::Base
  # Pick a unique cookie name to distinguish our session data from others'
  session :session_key => '_test_session_id'

  def ok_go
    @was_before_filter_called = true
  end

  protected
    def current_user
      User.find(1)
    end
end
