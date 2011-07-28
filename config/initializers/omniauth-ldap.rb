require 'omniauth/enterprise'
Rails.application.config.middleware.use OmniAuth::Builder do
  provider :ldap, :title => 'Test LDAP',
  :host => "localhost",
  :port => 1389,
  :method => :plain,
  :base => 'ou=uc3,dc=cdlib,dc=org',
  :uid => 'uid',
  :bind_dn => 'cn=Directory Manager',
  :password => 'ldap'
end
