module OmniAuth
  module Strategies
    autoload :Shibboleth, 'lib/shibboleth_omniauth'
  end
end

Rails.application.config.middleware.use OmniAuth::Builder do
  provider :shibboleth, "https://localhost:3000/Shibboleth.sso/Login"
end