require 'omniauth/openid'
require 'openid/store/filesystem'

Bibapp::Application.config.allow_open_id = true
Bibapp::Application.config.oauth_config =
    if File.exists?(File.join(Rails.root, 'config', 'omniauth.yml'))
      YAML.load_file(File.join(Rails.root, 'config', 'omniauth.yml'))
    else
      nil
    end

Rails.application.config.middleware.use OmniAuth::Builder do
  if Bibapp::Application.config.allow_open_id
    provider :open_id, OpenID::Store::Filesystem.new('/tmp')
  end
  if Bibapp::Application.config.oauth_config
    Bibapp::Application.config.oauth_config.each do |k, v|
      provider k, v['key'], v['secret']
    end
  end
end
