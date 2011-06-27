require 'config/personalize.rb'

module OmniAuth
  module Strategies
    autoload :Shibboleth, 'lib/shibboleth_omniauth'
  end
end

#change to the appropriate location for the shibboleth provider
shib_base = $REPOSITORY_BASE_URL.sub(/^http/, 'https')
Rails.application.config.middleware.use OmniAuth::Builder do
  provider :shibboleth, "#{shib_base}/Shibboleth.sso/Login"
end