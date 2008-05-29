# BibApp SMTP settings for sending email

# SMTP_CONFIG - Load settings from [bibapp]/config/smtp.yml
SMTP_CONFIG = "#{File.dirname(__FILE__)}/../../config/smtp.yml" unless defined? SMTP_CONFIG

SMTP_SETTINGS = YAML::load(File.read(SMTP_CONFIG))[RAILS_ENV]

# Actually initialize our ActionMailer with proper settings
if SMTP_SETTINGS and SMTP_SETTINGS['address']
  ActionMailer::Base.delivery_method = :smtp
  
  if SMTP_SETTINGS['username']
    ActionMailer::Base.smtp_settings = {
      :address => SMTP_SETTINGS['address'],
      :port => SMTP_SETTINGS['port'].to_i,
      :user_name => SMTP_SETTINGS['username'],
      :password => SMTP_SETTINGS['password'],
      :authentication => :login
    }
  else
    ActionMailer::Base.smtp_settings = {
      :address => SMTP_SETTINGS['address'],
      :port => SMTP_SETTINGS['port'].to_i
    }
  end
end