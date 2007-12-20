module AuthenticatedSystem
  protected
    # Returns true or false if the user is logged in.
    # Preloads @current_<%= file_name %> with the user model if they're logged in.
    def logged_in?
      (@current_<%= file_name %> ||= session[:<%= file_name %>] ? <%= class_name %>.find_by_id(session[:<%= file_name %>]) : :false).is_a?(<%= class_name %>)
    end
    
    # Accesses the current <%= file_name %> from the session.
    def current_<%= file_name %>
      @current_<%= file_name %> if logged_in?
    end
    
    # Store the given <%= file_name %> in the session.
    def current_<%= file_name %>=(new_<%= file_name %>)
      session[:<%= file_name %>] = new_<%= file_name %>.nil? ? nil : new_<%= file_name %>.id
      @current_<%= file_name %> = new_<%= file_name %>
    end
    
    # Check if the <%= file_name %> is authorized.
    #
    # Override this method in your controllers if you want to restrict access
    # to only a few actions or if you want to check if the <%= file_name %>
    # has the correct rights.
    #
    # Example:
    #
    #  # only allow nonbobs
    #  def authorize?
    #    current_<%= file_name %>.login != "bob"
    #  end
    def authorized?
       true
    end

    # Filter method to enforce a login requirement.
    #
    # To require logins for all actions, use this in your controllers:
    #
    #   before_filter :login_required
    #
    # To require logins for specific actions, use this in your controllers:
    #
    #   before_filter :login_required, :only => [ :edit, :update ]
    #
    # To skip this in a subclassed controller:
    #
    #   skip_before_filter :login_required
    #
    def login_required
      username, passwd = get_auth_data
      self.current_<%= file_name %> ||= <%= class_name %>.authenticate(username, passwd) || :false if username && passwd
      return true if logged_in? && authorized?
      respond_to do |accepts|
        accepts.html do
          session[:return_to] = request.request_uri
          redirect_to :controller => '<%= controller_file_name %>', :action => 'login'
        end
        accepts.xml do
          headers["Status"]           = "Unauthorized"
          headers["WWW-Authenticate"] = %(Basic realm="Web Password")
          render :text => "Could't authenticate you", :status => '401 Unauthorized'
        end
      end
      false
    end
    
    # Redirect as appropriate when an access request fails.
    #
    # The default action is to redirect to the login screen.
    #
    # Override this method in your controllers if you want to have special
    # behavior in case the <%= file_name %> is not authorized
    # to access the requested action.  For example, a popup window might
    # simply close itself.
    def access_denied
      redirect_to :controller => '/<%= controller_file_name %>', :action => 'login'
    end  
    
    # Store the URI of the current request in the session.
    #
    # We can return to this location by calling #redirect_back_or_default.
    def store_location
      session[:return_to] = request.request_uri
    end
    
    # Redirect to the URI stored by the most recent store_location call or
    # to the passed default.
    def redirect_back_or_default(default)
      session[:return_to] ? redirect_to_url(session[:return_to]) : redirect_to(default)
      session[:return_to] = nil
    end
    
    # Inclusion hook to make #current_<%= file_name %> and #logged_in?
    # available as ActionView helper methods.
    def self.included(base)
      base.send :helper_method, :current_<%= file_name %>, :logged_in?
    end

  private
    # gets BASIC auth info
    def get_auth_data
      user, pass = nil, nil
      # extract authorisation credentials 
      if request.env.has_key? 'X-HTTP_AUTHORIZATION' 
        # try to get it where mod_rewrite might have put it 
        authdata = request.env['X-HTTP_AUTHORIZATION'].to_s.split 
      elsif request.env.has_key? 'HTTP_AUTHORIZATION' 
        # this is the regular location 
        authdata = request.env['HTTP_AUTHORIZATION'].to_s.split  
      end 
       
      # at the moment we only support basic authentication 
      if authdata && authdata[0] == 'Basic' 
        user, pass = Base64.decode64(authdata[1]).split(':')[0..1] 
      end 
      return [user, pass] 
    end
end
