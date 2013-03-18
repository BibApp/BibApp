Rails.application.config.middleware.use OmniAuth::Builder do
  if Rails.env.production?
    #enter your Omniauth strategies here
    
  else
    provider :developer
  end
end
