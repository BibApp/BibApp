class Notifier < ActionMailer::Base
  def import_review_notification(user, import_id)
    setup_email(user)
    subject "BibApp - Batch import ready for review"
    body(:user => user, :import_id => import_id)
  end
  
  def error_summary(exception, clean_backtrace, params, session, request_env)
    recipients  "#{$SYSADMIN_EMAIL}"
    from        "#{$SYSADMIN_EMAIL}"
    subject     "BibApp - Exception summary: #{Time.now.strftime('%B %d, %Y')}"
    body(
      :exception => exception, 
      :clean_backtrace => clean_backtrace,
      :params => params, 
      :session => session, 
      :request_env => request_env
    )
  end

  protected
  def setup_email(user)
    recipients  user.email
    # SMTP_SETTINGS are loaded in /config/initializers/smtp.rb
    from        "BibApp <no-reply@bibapp.org>"
    sent_on     Time.now
  end
end
