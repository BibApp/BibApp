# Settings specified here will take precedence over those in config/environment.rb

# The production environment is meant for finished, "live" apps.
# Code is not reloaded between requests
Bibapp::Application.configure do
  config.cache_classes = true

# Use a different logger for distributed setups
# config.logger = SyslogLogger.new

# Full error reports are disabled and caching is turned on
  config.consider_all_requests_local = false
  config.action_controller.perform_caching = true

# Enable serving of images, stylesheets, and javascripts from an asset server
# config.action_controller.asset_host                  = "http://assets.example.com"

# Disable delivery errors, bad email addresses will be ignored
# config.action_mailer.raise_delivery_errors = false
  config.action_mailer.delivery_method = :sendmail
  config.action_mailer.sendmail_settings = {
      :location => '/usr/sbin/sendmail -t -i'
  }

# Uncomment if you need to see something running in production but with more logging
#  config.log_level = :debug

end