#To use OAuth you need to copy config/oauth.yml.example to 
#config/oauth.yml and fill in sections for each oauth provider
#that you want to use. Consule the Omniauth documentation for
#more details.
#Note that as Bibapp currently works the OAuth provider must
#return an email address for the user as one of the attributes
#for OAuth to be useable.
#Note that the view code does not currently provide anything
#to send you to your oauth provider - that would need to 
#be customized as well.
Bibapp::Application.config.oauth_config =
    if File.exists?(File.join(Rails.root, 'config', 'oauth.yml'))
      YAML.load_file(File.join(Rails.root, 'config', 'oauth.yml'))
    else
      nil
    end

Rails.application.config.middleware.use OmniAuth::Builder do
  if Bibapp::Application.config.oauth_config
    Bibapp::Application.config.oauth_config.each do |k, v|
      provider k, v['key'], v['secret']
    end
  end
end
