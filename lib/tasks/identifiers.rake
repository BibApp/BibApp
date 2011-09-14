# Rake tasks for SHERPA/RoMEO data for BibApp
#
require 'rubygems'
require 'rake'
require 'net/http'
require 'active_record'

namespace :identifiers do

  desc 'Update Publication identifier data.'
  task :validate_issn_isbns => :environment do
    puts "\nUpdating all Publication identifier data in BibApp...\n"

    publications = Publication.all
    publications.each do |publication|
      # Publication after save will run Publication.parse_identifiers
      publication.save
    end

    puts "Finished"
  end
end