# Rake tasks for SHERPA/RoMEO data for BibApp
#
require 'rubygems'
require 'rake'
require 'net/http'
require 'active_record'

namespace :sherpa do

  desc 'Update SHERPA/RoMEO data.'
  task :update_publisher_data => :environment do
    puts "\nUpdating all SHERPA/RoMEO data in BibApp...\n"

    #Call update_sherpa_data, which re-indexes *everything* in BibApp
    Publisher.update_sherpa_data

    puts "Finished!"
  end
  
  # @TODO: 
  # Someday we want to download the SHERPA data via net/http...
  # But, the SHERPA data is not cached, so the net/http calls always times out
end