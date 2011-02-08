# BibApp SMTP settings for sending email

# SMTP_CONFIG - Load settings from [bibapp]/config/smtp.yml
SMTP_CONFIG = "#{File.dirname(__FILE__)}/../../config/smtp.yml" unless defined? SMTP_CONFIG

SMTP_SETTINGS = YAML::load(File.read(SMTP_CONFIG))[Rails.env] if File.exists?(SMTP_CONFIG)

# Actually initialize our ActionMailer with proper settings
if SMTP_SETTINGS and SMTP_SETTINGS['address']
  #Always send mail via SMTP
  ActionMailer::Base.delivery_method = :smtp
  
  # default port to 25
  port = SMTP_SETTINGS['port'] ? SMTP_SETTINGS['port'].to_i : 25
  
  #determine if login required for SMTP server
  if SMTP_SETTINGS['username'] and !SMTP_SETTINGS['username'].empty?
    ActionMailer::Base.smtp_settings = {
      :address => SMTP_SETTINGS['address'],
      :port => port,
      :domain => SMTP_SETTINGS['domain'],
      :user_name => SMTP_SETTINGS['username'],
      :password => SMTP_SETTINGS['password'],
      :authentication => :login
    }
  else
    ActionMailer::Base.smtp_settings = {
      :address => SMTP_SETTINGS['address'],
      :port => port,
      :domain => SMTP_SETTINGS['domain']
    }
  end
end