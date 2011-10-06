#This seems to be necessary for some of the tests that use the _path and _url helpers
#E.g. in imports_helper_spec
#I think this is because the controller machinery doesn't get engaged to set a locale
Bibapp::Application.configure do
  routes.default_url_options = {:locale => 'en'}
end
