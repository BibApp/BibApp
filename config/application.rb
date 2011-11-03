require File.expand_path('../boot', __FILE__)

require 'rails/all'
require 'fileutils'

# If you have a Gemfile, require the gems listed there, including any gems
# you've limited to :test, :development, or :production.
Bundler.require(:default, Rails.env) if defined?(Bundler)

#AUTHORIZATION_MIXIN = "object roles"
Authorization::Base::LOGIN_REQUIRED_REDIRECTION = {:controller => '/user_sessions', :action => 'new'}
Authorization::Base::PERMISSION_DENIED_REDIRECTION = {:controller => 'works', :action => 'index'}
Authorization::Base::STORE_LOCATION_METHOD = :store_location

module Bibapp
  class Application < Rails::Application

    #for each available locale dump the part of config/locales/<locale>.yml that jsperanto needs as JSON into
    #public/javascripts/translations
    def self.create_jsperanto_locales(locales)
      json_dir = File.join(Rails.root, 'public', 'javascripts', 'translations')
      yaml_dir = File.join(Rails.root, 'config', 'locales')
      FileUtils.mkdir_p(json_dir)

      locales.each do |locale|
        translations = YAML.load_file(File.join(yaml_dir, "#{locale}.yml"))
        #json = translations[locale.to_s]['jsperanto'].to_json
        json = JSON.pretty_generate(translations[locale.to_s]['jsperanto'])
        File.open(File.join(json_dir, "#{locale}.json"), "w") do |f|
          f.puts(json)
        end
      end
    end

    # Settings in config/environments/* take precedence over those specified here.
    # Application configuration should go into files in config/initializers
    # -- all .rb files in that directory are automatically loaded.

    # Custom directories with classes and modules you want to be autoloadable.
    # config.autoload_paths += %W(#{config.root}/extras)
    config.autoload_paths += %W( #{Rails.root}/app/models/work_subclasses )
    config.autoload_paths += %W( #{Rails.root}/app/models/attachment_subclasses )
    config.autoload_paths += %W( #{Rails.root}/app/models/identifier_subclasses )
    config.autoload_paths += Dir["#{Rails.root}/vendor/gems/**"].map do |dir|
      File.directory?(lib = "#{dir}/lib") ? lib : dir
    end

    # Only load the plugins named here, in the order given (default is alphabetical).
    # :all can be used as a placeholder for all plugins not explicitly named.
    # config.plugins = [ :exception_notification, :ssl_requirement, :all ]

    # Activate observers that should always be running
    config.active_record.observers = :user_observer, :index_observer

    # Set Time.zone default to the specified zone and make Active Record auto-convert to this zone.
    # Run "rake -D time" for a list of tasks for finding time zone names. Default is UTC.
    # config.time_zone = 'Central Time (US & Canada)'

    # Specify desired locales in config/locales.yml. If that doesn't exist use English only.
    # The first in the list will be the default locale by default.
    locales = YAML.load_file(File.join(Rails.root, 'config', 'locales.yml')).collect { |l| l.to_sym } rescue [:en]
    config.i18n.available_locales = locales
    config.i18n.default_locale = locales.first
    config.i18n.load_path += Dir[Rails.root.join('config', 'locales', '**', '*.{rb,yml}').to_s]
    self.create_jsperanto_locales(locales)

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

require 'error_handler'
require 'index'
