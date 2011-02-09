class UserSessionsController < ApplicationController
  # Don't write passwords as plain text to the log files
  filter_parameter_logging :password, :password_confirmation

  before_filter :require_no_user, :only => [:new, :create]
  before_filter :require_user, :only => :destroy

  def new
    @user_session = UserSession.new
  end

  def create
    @user_session = UserSession.new(params[:user_session])
    if @user_session.save
      flash[:notice] = "Login successful!"
      redirect_back_or_default root_url
    else
      render :action => :new
    end
  end

  def destroy
    current_user_session.destroy
    flash[:notice] = "Logout successful!"
    redirect_back_or_default new_user_session_url
  end

  # load new.html.haml
#  def new
#  end
#
#  # Create - Login a user into the system
#  def create
#    self.current_user = User.authenticate(params[:login], params[:password])
#    if logged_in?
#      if params[:remember_me] == "1"
#        current_user.remember_me unless current_user.remember_token?
#        cookies[:auth_token] = { :value => self.current_user.remember_token , :expires => self.current_user.remember_token_expires_at }
#      end
#      redirect_back_or_default($APPLICATION_URL)
#      flash[:notice] = "Logged in successfully"
#    else
#      flash[:error] = "Username or password was invalid."
#      render :action => 'new'
#    end
#  end
#
#  # Destroy - Logout a user from the system
#  def destroy
#    self.current_user.forget_me if logged_in?
#    cookies.delete :auth_token
#    reset_session
#    flash[:notice] = "You have been logged out."
#    redirect_back_or_default($APPLICATION_URL)
#  end
#
#  def saved
#    @saved   = session[:saved]
#    @page   = params[:page] || 1
#    @rows   = params[:rows] || 10
#    @export = params[:export] || ""
#
#    if !@saved.nil?
#      @works = Work.paginate(
#        :page => @page,
#        :per_page => @rows,
#        :conditions => ["id in (?)", @saved.items]
#      )
#    end
#
#    if @export && !@export.empty?
#      works = Work.find(@works.collect{|c| c.id}, :order => "publication_date desc")
#      ce = WorkExport.new
#      @works = ce.drive_csl(@export,works)
#    end
#  end
end
