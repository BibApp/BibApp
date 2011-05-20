require 'omniauth/openid'
require 'openid/store/filesystem'

Rails.application.config.middleware.use OmniAuth::Builder do
  provider :open_id, OpenID::Store::Filesystem.new('/tmp')
end
