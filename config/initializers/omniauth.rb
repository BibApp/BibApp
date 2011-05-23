require 'omniauth/openid'
require 'openid/store/filesystem'

Bibapp::Application.allow_open_id = true
Bibapp::Application.oauth_config =
    if File.exists?(File.join(Rails.root, 'config', 'omniauth.yml'))
      YAML.load_file(File.join(Rails.root, 'config', 'omniauth.yml'))
    else
      nil
    end

Rails.application.config.middleware.use OmniAuth::Builder do
  if Bibapp::Application.allow_open_id
    provider :open_id, OpenID::Store::Filesystem.new('/tmp')
  end
  if Bibapp::Application.oauth_config
    Bibapp::Application.oauth_config.each do |k, v|
      provider k, v['key'], v['secret']
    end
  end
end
