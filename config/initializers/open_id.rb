require 'omniauth/openid'
require 'openid/store/filesystem'

#If you want to use open id then set this to true and define
#any applicable open id providers in config/open_id.yml
#The login view will provide a button to each specified 
#OpenID provider and one for generic OpenID - you may 
#want to customize this as it's crude at the moment.
Bibapp::Application.config.allow_open_id = false

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
