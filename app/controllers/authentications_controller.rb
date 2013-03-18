class AuthenticationsController < ApplicationController
  def create
    omniauth = request.env['omniauth.auth']
    authentication = Authentication.find_by_provider_and_uid(omniauth['provider'], omniauth['uid'])

    if authentication
      # User is already registered with application
      flash[:info] = t('common.authentications.flash_sign_in')
      sign_in_and_redirect(authentication.user)
    elsif user = current_user || User.find_by_email(omniauth['info']['email'])
      # User is signed in but has not already authenticated with this social network
      # OR
      #user already has a local account - connect it properly to an authentication
      user.authentications.create!(:provider => omniauth['provider'], :uid => omniauth['uid'])
      user.apply_omniauth(omniauth)
      user.save
      flash[:info] = t('common.authentications.flash_authentication')
      redirect_to root_url
    else
      # User is new to this application
      begin
        user = User.new_from_omniauth!(omniauth)
        flash[:info] = t('common.authentications.flash_create')
        user.authentications.create(:provider => omniauth['provider'], :uid => omniauth['uid'])
        sign_in_and_redirect(user)
      rescue
        session[:omniauth] = omniauth.except('extra')
        redirect_to signup_path and return
      end
    end
  end

  def destroy
    @authentication = current_user.authentications.find(params[:id])
    @authentication.destroy
    flash[:notice] = t('common.authentications.flash_destroy')
    redirect_to authentications_url
  end

  private
  def sign_in_and_redirect(user)
    unless current_user
      user_session = UserSession.new(user)
      user_session.save
    end
    redirect_to root_url
  end
end
