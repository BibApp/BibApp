# Settings specified here will take precedence over those in config/environment.rb

# In the development environment your application's code is reloaded on
# every request.  This slows down response time but is perfect for development
# since you don't have to restart the webserver when you make code changes.
Bibapp::Application.configure do
  config.cache_classes = false

# Log error messages when you accidentally call methods on nil.
  config.whiny_nils = true

# Show full error reports \
  config.consider_all_requests_local = false

#control caching
  # disable caching
  config.action_controller.perform_caching = false

  #enable caching on the file system
  #config.action_controller.perform_caching = true
  #config.action_controller.cache_store = :file_store, File.join(Rails.root, 'tmp', 'cache', Rails.env)

# Don't want the mailer to send.
  config.action_mailer.delivery_method = :test
  config.action_mailer.raise_delivery_errors = false
end
