require 'fileutils'

#Build path to SWORD config file
sword_config = File.dirname(__FILE__) + '/../../../config/sword.yml'

#Copy over template SWORD config if not already there
FileUtils.cp File.dirname(__FILE__) + '/sword.yml.tmpl', sword_config unless File.exist?(sword_config)

#Output readme file
puts IO.read(File.join(File.dirname(__FILE__), 'README'))
