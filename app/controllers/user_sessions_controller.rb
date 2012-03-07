class UserSessionsController < ApplicationController

  before_filter :require_no_user, :only => [:new, :create]
  before_filter :require_user, :only => [:destroy]

  def new
    @user_session = UserSession.new
  end

  def create
    @user_session = UserSession.new(params[:user_session])
    @user_session.save do |result|
      if result
        flash[:notice] = t('common.user_sessions.flash_create_successful', :locale => @user_session.record.default_locale)
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
    if @export = params[:export]
      ce = WorkExport.new
      @works = ce.drive_csl(params[:export], @works.sort_by {|w| w.publication_date_string}.reverse)
    end
  end

  protected

  def after_login_destination
    #avoid login -> login infinite redirect
    user = @user_session.record
    if params[:return_to] and params[:return_to].match(/\/login/)
      if user and user.person
        return person_url(user.person, :locale => user.default_locale)
      else
        return works_url(:locale => user.default_locale)
      end
    end
    params[:return_to] || works_url(:locale => user.default_locale)
  end
end
