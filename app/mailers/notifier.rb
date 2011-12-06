class Notifier < ActionMailer::Base

  def import_review_notification(import)
    user = import.user
    with_setup_and_mailing(user) do
      @subject = "BibApp - Batch import ready for review"
      @subject = t('common.notifier.import_review_subject', :app_name => t('personalize.application_name'))
      @user = user
      @import_id = import.id
      @locale = user.default_locale || I18n.default_locale
    end
  end

  def batch_import_persons_notification(user_id, results, filename = "Unknown")
    @user = User.find(user_id)
    with_setup_and_mailing(@user) do
      @subject = t('common.notifier.import_persons_subject', :app_name => t('personalize.application_name'))
      @email = @user.email
      @results = results
      @filename = filename
    end
  end

  def error_summary(exception, clean_backtrace, params, session)
    with_setup_and_mailing do
      @recipients = $SYSADMIN_EMAIL
      @from = $SYSADMIN_EMAIL
      @subject = t('common.notifier.error_summary_subject', :app_name => t('personalize.application_name'), :time => Time.now.strftime('%B %d, %Y'))
      @exception = exception
      @clean_backtrace = clean_backtrace
      @params = params
      @session = session
    end
  end

  protected

  #do setup and emailing while yielding to a block in between to do any additional
  #actions, set up instance variables, etc.
  def with_setup_and_mailing(user = nil)
    @recipients = user.email if user
    @from = "BibApp <no-reply@bibapp.org>"
    @from = t('common.notifier.from', :no_reply_email => ((SMTP_SETTINGS['from_email'] if SMTP_SETTINGS) || $NO_REPLY_EMAIL || 'bibapp-noreply@bibapp.org'),
      :app_name => t('personalize.application_name'))
    yield
    mail(:to => @recipients, :subject => @subject, :from => @from)
  end

end
