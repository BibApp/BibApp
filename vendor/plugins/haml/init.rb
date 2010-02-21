begin
  require File.join(File.dirname(__FILE__), 'lib', 'haml') # From here
rescue LoadError
  require 'haml' if defined? Haml # From gem
end

# Load Haml and Sass
if defined? Haml
  Haml.init_rails(binding)
end
