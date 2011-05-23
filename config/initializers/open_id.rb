require 'omniauth/openid'
require 'openid/store/filesystem'

Bibapp::Application.config.allow_open_id = true

if Bibapp::Application.config.allow_open_id
  Rails.application.config.middleware.use OmniAuth::Builder do
    provider :open_id, OpenID::Store::Filesystem.new('/tmp')
  end
  config_file = File.join(Rails.root, 'config', 'open_id.yml')
  if File.exists?(config_file)
    Bibapp::Application.config.open_id_presets =
        YAML.load_file(config_file)['presets'] || []
  end

end
