class UserMailer < ActionMailer::Base

  def signup_notification(user)
    with_setup_and_mailing(user) do
      @url = "#{$APPLICATION_URL.chomp('/')}/activate/#{user.activation_code}"
      @subject += t('common.user_mailer.signup_notification_subject')
    end
  end

  def activation(user)
    with_setup_and_mailing(user) do
      @subject += t('common.user_mailer.activation_subject')
      @url = "#{$APPLICATION_URL.chomp('/')}/"
    end
  end


  def new_password(user, new_password)
    with_setup_and_mailing(user) do
      @subject += t('common.user_mailer.new_password_subject')
      @url = "#{$APPLICATION_URL.chomp('/')}/login"
    end
  end

  def update_email(user, url)
    with_setup_and_mailing(user) do
      @subject += t('common.user_mailer.update_email_subject')
      @url = url
    end
  end

  protected

  #do the common setup and common mailing while yielding to a block
  #which can set or modify instance variables as needed
  def with_setup_and_mailing(user)
    from = SMTP_SETTINGS['from_email'] if SMTP_SETTINGS
    from ||= $NO_REPLY_EMAIL || 'bibapp-noreply@bibapp.org'
    @subject = "[#{t('personalize.application_name')}] "
    @user = user
    yield
    mail(:to => user.email, :subject => @subject, :from => from)
  end

end
