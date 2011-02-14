class Notifier < ActionMailer::Base
  def import_review_notification(user, import_id)
    setup_email(user)
    subject "BibApp - Batch import ready for review"
    body(:user => user, :import_id => import_id)
  end
  
   def batch_import_persons_notification(user_id, results, filename = "Unknown")
    require 'config/personalize.rb'
    
    user = User.find(user_id)
    setup_email(user)
    subject "BibApp Synapse - batch upload of persons has completed"
    body(:login => user.login, :results => results, :filename => filename)
  end

  
  
  def error_summary(exception, clean_backtrace, params, session)
    recipients  "#{$SYSADMIN_EMAIL}"
    from        "#{$SYSADMIN_EMAIL}"
    subject     "BibApp - Exception summary: #{Time.now.strftime('%B %d, %Y')}"
    body(
      :exception => exception, 
      :clean_backtrace => clean_backtrace,
      :params => params, 
      :session => session
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
