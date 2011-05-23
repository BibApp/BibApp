class UserSessionsController < ApplicationController

  before_filter :require_no_user, :only => [:new, :create]
  before_filter :require_user, :only => [:destroy, :saved]
  helper UserSessionsHelper

  def new
    @user_session = UserSession.new
  end

  def create
    @user_session = UserSession.new(params[:user_session])
    @user_session.save do |result|
      if result
        flash[:notice] = "Login successful!"
        redirect_to after_login_destination
      else
        render :action => :new
      end
    end
  end

  def destroy
    current_user_session.destroy
    flash[:notice] = "Logout successful!"
    session[:no_shibboleth] = true
    redirect_back_or_default root_url
  end

  def saved
    @works = session[:saved].all_works
  end

  def login_shibboleth
    session[:no_shibboleth] = false
    if current_user
      redirect_to after_login_destination
    else
      redirect_to(shibboleth_login_url, :return_to => params[:return_to])
    end
  end

  protected

  def shibboleth_login_url
    url = root_url(:protocol => 'https') + "Shibboleth.sso/Login"
    if return_to = params[:return_to] || session[:return_to]
      target = root_url(:protocol => 'https') + return_to
      url = "#{url}?target=#{CGI.escape(target)}"
    end
    return url
  end

  def after_login_destination
    #avoid login -> login infinite redirect
    return_to = params[:return_to] || session[:return_to]
    if return_to and (return_to.match(/\/login/) || return_to.match(/\/user_sessions\/new/))
      if user = (current_user or @user_session.record) and user.person
        return person_url(user.person)
      else
        return root_url
      end
    end
    return_to || root_url
  end
end
