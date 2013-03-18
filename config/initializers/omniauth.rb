Rails.application.config.middleware.use OmniAuth::Builder do
  if Rails.env.production?
    #enter your Omniauth strategies here
    opts = YAML.load_file(File.join(Rails.root, 'config', 'shibboleth.yml'))[Rails.env]
    provider :shibboleth, opts.symbolize_keys
    Bibapp::Application.shibboleth_host = opts['host']
  else
    provider :developer
  end
end
