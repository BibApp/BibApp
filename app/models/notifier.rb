class Notifier < ActionMailer::Base
  def import_review_notification(user, import_id)
    setup_email(user)
    subject "BibApp - Batch import ready for review"
    body(:user => user, :import_id => import_id)
  end

  protected
  def setup_email(user)
    recipients  user.email
    # SMTP_SETTINGS are loaded in /config/initializers/smtp.rb
    from        "BibApp <no-reply@bibapp.org>"
    sent_on     Time.now
  end
end
