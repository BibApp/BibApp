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
        if user.activated_at
          @new_password = User.random_password
          user.password = user.password_confirmation = @new_password
          user.save_without_session_maintenance
          UserMailer.new_password(user, @new_password).deliver

          format.html do
            flash[:notice] = t('common.passwords.flash_create_sent', :email => params[:password][:email])
            redirect_to login_url
          end
        else
          flash[:notice] = t('common.passwords.flash_create_inactive')
          UserMailer.signup_notification(user).deliver
          format.html do
            redirect_to root_url
          end
        end
      else
        flash[:notice] = t('common.passwords.flash_create_no_account')
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
        flash[:notice] = t('common.passwords.flash_update_success')
        format.html { redirect_to edit_user_path(@user) }
      else
        if !@user.errors.empty?
          flash[:notice] = t('common.passwords.flash_update_bad_match')
        else
          flash[:notice] = t('common.passwords.flash_update_incorrect')
        end
        format.html { render :action => 'edit' }
      end
    end
  end

end
