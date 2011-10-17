class UserMailer < ActionMailer::Base

  def signup_notification(user)
    with_setup_and_mailing(user) do
      @url = "#{$APPLICATION_URL.chomp('/')}/activate/#{user.activation_code}"
      @subject += 'Please activate your new account'
    end
  end

  def activation(user)
    with_setup_and_mailing(user) do
      @subject += 'Your account has been activated!'
      @url = "#{$APPLICATION_URL.chomp('/')}/"
    end
  end


  def new_password(user, new_password)
    with_setup_and_mailing(user) do
      @subject += 'New password'
      @url = "#{$APPLICATION_URL.chomp('/')}/login"
    end
  end

  def update_email(user, url)
    with_setup_and_mailing(user) do
      @subject += 'Email address update confirmation'
      @url = url
    end
  end

  protected

  #do the common setup and common mailing while yielding to a block
  #which can set or modify instance variables as needed
  def with_setup_and_mailing(user)
    from = SMTP_SETTINGS['from_email'] if SMTP_SETTINGS
    @subject = "[#{$APPLICATION_NAME}] "
    @user = user
    yield
    mail(:to => user.email, :subject => @subject, :from => from)
  end

end
