# This controller handles the login/logout function of the site.  
class SessionsController < ApplicationController
  
  # Don't write passwords as plain text to the log files  
  filter_parameter_logging :password, :password_confirmation 
  
  # load new.html.haml
  def new
  end

  # Create - Login a user into the system
  def create
    self.current_user = User.authenticate(params[:login], params[:password])
    if logged_in?
      if params[:remember_me] == "1"
        current_user.remember_me unless current_user.remember_token?
        cookies[:auth_token] = { :value => self.current_user.remember_token , :expires => self.current_user.remember_token_expires_at }
      end
      redirect_back_or_default($APPLICATION_URL)
      flash[:notice] = "Logged in successfully"
    else
      flash[:error] = "Username or password was invalid."
      render :action => 'new'
    end
  end

  # Destroy - Logout a user from the system
  def destroy
    self.current_user.forget_me if logged_in?
    cookies.delete :auth_token
    reset_session
    flash[:notice] = "You have been logged out."
    redirect_back_or_default($APPLICATION_URL)
  end
  
  def cart
    @cart   = session[:cart]
    @page   = params[:page] || 1
    @rows   = params[:rows] || 10
    @export = params[:export] || ""
    
    if !@cart.nil?
      @works = Work.paginate(
        :page => @page, 
        :per_page => @rows,
        :conditions => ["id in (?)", @cart.items]
      )
    end
    
    if @export && !@export.empty?
      works = Work.find(@works.collect{|c| c.id}, :order => "publication_date desc")
      ce = WorkExport.new
      @works = ce.drive_csl(@export,works)
    end
  end
end
