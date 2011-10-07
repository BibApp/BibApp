class UserSessionsController < ApplicationController

  before_filter :require_no_user, :only => [:new, :create]
  before_filter :require_user, :only => [:destroy, :saved]

  def new
    @user_session = UserSession.new
  end

  def create
    @user_session = UserSession.new(params[:user_session])
    @user_session.save do |result|
      if result
        flash[:notice] = t('common.user_sessions.flash_create_successful')
        redirect_to after_login_destination
      else
        render :action => :new
      end
    end
  end

  def destroy
    current_user_session.destroy
    flash[:notice] = t('common.user_sessions.flash_destroy_successful')
    redirect_back_or_default root_url
  end

  def saved
    @works = session[:saved].all_works
  end

  protected

  def after_login_destination
    #avoid login -> login infinite redirect
    if params[:return_to] and params[:return_to].match(/\/login/)
      if user = @user_session.record and user.person
        return person_url(user.person)
      else
        return root_url
      end
    end
    params[:return_to] || root_url
  end
end
