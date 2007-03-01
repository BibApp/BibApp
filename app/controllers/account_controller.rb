class AccountController < ApplicationController
  # Be sure to include AuthenticationSystem in Application Controller instead
  

  # say something nice, you goof!  something sweet.
  def index
    redirect_to(:action => 'signup') unless logged_in? || User.count > 0
  end

  def login
    return unless request.post?
    self.current_user = User.authenticate(params[:login], params[:password])
    if current_user
      redirect_back_or_default(:controller => '/', :action => 'index')
      flash[:notice] = "Logged in successfully"
    end
  end

  def signup
    @user = User.new(params[:user])
    return unless request.post?
    if @user.save
      flash[:notice] = "Thanks for signing up!"
      self.current_user = User.authenticate(params[:login], params[:password])
      redirect_back_or_default(:controller => '/groups', :action => 'index')
    end
  end
  
  def logout
    self.current_user = nil
    reset_session
    flash[:notice] = "You have been logged out."
    redirect_back_or_default(:controller => '/account', :action => 'index')
  end
end
