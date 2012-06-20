# Rake tasks peculiar to connections

namespace :connections do

  #Because of how passenger standalone uses system information to
  #determine where nginx should live it thinks it should be in a
  #different place for our staging and production servers. Hence on
  #production it doesn't find an existing version (even though we sync
  #them from the staging server) and tries to build, which fails. This
  #task figures out where it wants it and makes a link. So this should
  #be run on production before trying to start passenger if there is
  #any change.

  #The one slightly dodgy part is figuring out which (if there are more than one)
  #synced version to use.

  desc 'Figure out passenger standalone to use and link to it'
  task :link_passenger_standalone => :environment do
    require 'phusion_passenger'
    require 'phusion_passenger/platform_info/binary_compatibility'
    require 'fileutils'
    passenger_dir = "/services/ideals-bibapp/.passenger/standalone"
    system_info = PhusionPassenger::PlatformInfo.passenger_binary_compatibility_id
    version_info = PhusionPassenger::VERSION_STRING
    link_name = "#{version_info}-#{system_info}"
    Dir.chdir(passenger_dir) do
      #remove old links
      Dir["*"].each do |f|
        if File.symlink?(f)
          puts "Unlinking #{f}"
          File.unlink(f)
        end
      end
      #guess which version to use - we don't try to be very sophisicated here
      #just take the one with the latest mtime
      source_dir = Dir["*gcc*"].sort_by { |x| File.mtime(x) }.reverse.first
      #link
      puts "linking source #{source_dir} to #{link_name}"
      FileUtils.ln_s(source_dir, link_name)
    end
  end
end
