class UserSessionsController < ApplicationController

  before_filter :require_no_user, :only => [:new, :create]
  before_filter :require_user, :only => [:destroy, :saved]
  helper UserSessionsHelper
  
  def new
    @user_session = UserSession.new
  end

  def create
    @user_session = UserSession.new(params[:user_session])
    if @user_session.save
      flash[:notice] = "Login successful!"
      redirect_to params[:return_to] || root_url
    else
      render :action => :new
    end
  end

  def destroy
    current_user_session.destroy
    flash[:notice] = "Logout successful!"
    redirect_back_or_default new_user_session_url
  end

  def saved
    @works = session[:saved].all_works
  end

  def login_shibboleth
    if current_user
      redirect_back_or_default(root_url)
    else
      redirect_to(shibboleth_login_url)
    end
  end

  protected
  
  def shibboleth_login_url
    root_url(:protocol => 'https') + "Shibboleth.sso/Login"
  end

end
