#This exists because of the funny way that Rails caching (particularly fragment caching) works.
#We want to expire based on model changes, using sweepers as observers, not based on controller actions
#To do this you can make sweepers and hook them up as observers in config/application.rb. However,
#when they get called from models there is no controller present, so the url_for generation of cache keys fails.

#The aim here is to make an interface that works similarly but translates directly into string keys, which can
#then be used directly in both views and sweepers.
#We'll make keys of the form /controller/action/locale?key1=val1&key2=val2.... Locale by default will be I18n.locale.
#controller and action by default will be 'default'. You really should set them, though
module CacheHelper

  def make_key(args = {})
    controller = args.delete(:controller) || 'default'
    action = args.delete(:action) || 'default'
    locale = args.delete(:locale) || I18n.locale || I18n.default_locale
    rest = args.keys.sort.collect { |k| "#{k}=#{args[k]}" }.join('&')
    "/#{controller}/#{action}/#{locale}?#{rest}"
  end

  def bibapp_cache(name = {}, options = nil, &block)
    cache(make_key(name), options) { block.call }
  end

  def bibapp_expire_fragment(name = {}, options = nil)
    ensure_controller do
      expire_fragment(make_key(name), options)
    end
  end

  def bibapp_expire_fragment_all_locales(name = {}, options = nil)
    I18n.available_locales.each do |locale|
      bibapp_expire_fragment(name.merge(:locale => locale), options)
    end
  end

  def ensure_controller
    self.controller ||= ActionController::Base.new
    yield
  end

end