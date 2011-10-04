# This controller allows users to change their passwords, or request a new password
#   Code borrowed from: http://blog.compulsivoco.com/2008/03/24/how-to-change-or-reset-your-password-with-restful_authentication/
class PasswordsController < ApplicationController

  # require user is logged in, except for "forgot password" page
  before_filter :login_required, :only => [:edit, :update]

  # POST /passwords
  # Forgot password
  def create
    respond_to do |format|

      if user = User.find_by_email(params[:password][:email])
        @new_password = User.random_password
        user.password = user.password_confirmation = @new_password
        user.save_without_session_maintenance
        UserMailer.new_password(user, @new_password).deliver

        format.html do
          flash[:notice] = "We sent a new password to #{params[:password][:email]}"
          redirect_to login_url
        end
      else
        flash[:notice] = "Sorry, we cannot find that account.  Try again."
        format.html { render :action => "new" }
      end
    end
  end

  # GET /users/1/password/edit
  # Changing password
  def edit
    @user = current_user
  end

  # PUT /users/1/password
  # Changing password
  def update
    @user = current_user

    old_password = params[:old_password]

    @user.attributes = params[:user]

    respond_to do |format|
      if @user.valid_password?(old_password) && @user.save
        flash[:notice] = "Your password was updated successfully."
        format.html { redirect_to edit_user_path(@user) }
      else
        if !@user.errors.empty?
          flash[:notice] = "Sorry, your new password didn't match the confirmation.  Try again."
        else
          flash[:notice] = "Sorry, your old password was incorrect. Try again."
        end
        format.html { render :action => 'edit' }
      end
    end
  end

end
