class UserMailer < ActionMailer::Base
  def signup_notification(user)
    setup_email(user)
    @subject    += 'Please activate your new account'
  
    @url  = "#{$APPLICATION_URL.chomp('/')}/activate/#{user.activation_code}"
  
  end
  
  def activation(user)
    setup_email(user)
    @subject    += 'Your account has been activated!'
    @url  = "#{$APPLICATION_URL.chomp('/')}/"
  end
  
  def new_password(user, new_password)
    setup_email(user)
    @subject    += 'New password'
    @url  = "#{$APPLICATION_URL.chomp('/')}/login"
  end
  
  protected
    def setup_email(user)
      @recipients  = "#{user.email}"
      # SMTP_SETTINGS are loaded in /config/initializers/smtp.rb
      @from        = SMTP_SETTINGS['from_email'] if SMTP_SETTINGS
      @subject     = "[#{$APPLICATION_NAME}] "
      @sent_on     = Time.now
      @user = user
    end
end
