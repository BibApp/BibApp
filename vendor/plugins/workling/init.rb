#Customization for BibApp - We don't want to require MemCache, since we don't use it by default!
#Technically, Workling only uses MemCache if you are using the StarlingRunner
#gem 'memcache-client'
require 'memcache' if defined? MemCache

Workling::Discovery.discover!