require 'config/personalize'

module OmniAuth
  module Strategies
    autoload :Shibboleth, 'lib/shibboleth_omniauth'
  end
end

#change to the appropriate location for the shibboleth provider
Rails.application.config.middleware.use OmniAuth::Builder do
  provider :shibboleth, "#{$APPLICATION_URL}Shibboleth.sso/Login", 'urn:mace:incommon:uiuc.edu'
end

