require File.expand_path('../boot', __FILE__)

require 'rails/all'

# If you have a Gemfile, require the gems listed there, including any gems
# you've limited to :test, :development, or :production.
Bundler.require(:default, Rails.env) if defined?(Bundler)

#AUTHORIZATION_MIXIN = "object roles"
{:LOGIN_REQUIRED_REDIRECTION => {:controller => '/user_sessions', :action => 'new'},
 :PERMISSION_DENIED_REDIRECTION => {:controller => 'works', :action => 'index'},
 :STORE_LOCATION_METHOD => :store_location}.each do |k, v|
  Authorization::Base.send(:remove_const, k) if Authorization::Base.const_defined?(k)
  Authorization::Base.const_set(k, v)
end

module Bibapp
  class Application < Rails::Application

    # Settings in config/environments/* take precedence over those specified here.
    # Application configuration should go into files in config/initializers
    # -- all .rb files in that directory are automatically loaded.

    # Custom directories with classes and modules you want to be autoloadable.
    # config.autoload_paths += %W(#{config.root}/extras)
    config.autoload_paths += %W( #{Rails.root}/app/models/work_subclasses )
    config.autoload_paths += %W( #{Rails.root}/app/models/attachment_subclasses )
    config.autoload_paths += %W( #{Rails.root}/app/models/identifier_subclasses )
    config.autoload_paths += %W( #{Rails.root}/app/sweepers )
    config.autoload_paths += Dir["#{Rails.root}/vendor/gems/**"].map do |dir|
      File.directory?(lib = "#{dir}/lib") ? lib : dir
    end

    # Only load the plugins named here, in the order given (default is alphabetical).
    # :all can be used as a placeholder for all plugins not explicitly named.
    # config.plugins = [ :exception_notification, :ssl_requirement, :all ]

    # Activate observers that should always be running
    config.active_record.observers = :user_observer, :index_observer, :publications_sweeper

    # Set Time.zone default to the specified zone and make Active Record auto-convert to this zone.
    # Run "rake -D time" for a list of tasks for finding time zone names. Default is UTC.
    # config.time_zone = 'Central Time (US & Canada)'

    # Specify desired locales in config/locales.yml. If that doesn't exist use English only.
    # The first in the list will be the default locale by default.
    locales = YAML.load_file(File.join(Rails.root, 'config', 'locales.yml')).collect { |l| l.to_sym } rescue [:en]
    config.i18n.available_locales = locales
    config.i18n.default_locale = locales.first
    config.i18n.load_path += Dir[Rails.root.join('config', 'locales', '**', '*.{rb,yml}').to_s]

    # JavaScript files you want as :defaults (application.js is always included).
    # config.action_view.javascript_expansions[:defaults] = %w(jquery rails)

    # Configure the default encoding used in templates for Ruby 1.9.
    config.encoding = "utf-8"

    # Configure sensitive parameters which will be filtered from the log file.
    config.filter_parameters += [:password, :password_confirmation, :old_password]

    #log deprecations
    config.active_support.deprecation = :log
  end

end

require File.join(Rails.root, 'config', 'personalize.rb')
require 'error_handler'
require 'index'
