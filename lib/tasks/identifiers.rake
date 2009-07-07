# Rake tasks for SHERPA/RoMEO data for BibApp
#
require 'rubygems'
require 'rake'
require 'net/http'
require 'active_record'
require "#{File.dirname(__FILE__)}/../../config/environment.rb"

namespace :identifiers do

  desc 'Update Publication identifier data.'
  task :validate_issn_isbns do
    puts "\nUpdating all Publication identifier data in BibApp...\n"
    
    publications = Publication.find(:all)
    publications.each do |publication|
      puts "\n=== #{publication.name}: #{publication.issn_isbn} ==="
      
      if publication.issn_isbn.blank?
        next
      else
        # Loop thru all publication issn_isbn values
        publication.issn_isbn.each do |issn_isbn| 

          # Field might be separated
          issn_isbn.split("; ").each do |identifier|

            # No spaces, no hyphens, no quotes -- @TODO: Do this better!
            identifier = identifier.strip.gsub(" ", "").gsub("-", "").gsub('"', "")

            # Init new Identifier
            id = Identifier.new
            parsed_id = id.parse(identifier)
            if !parsed_id[0].blank?
              puts "--- #{parsed_id[0]} - #{parsed_id[1]}"
              pub_id = Identifier.find_or_initialize_by_name(:name => parsed_id[1])
              pub_id[:type] = parsed_id[0] if !parsed_id[0].blank?
              pub_id.save
              puts "Pub: #{pub_id.inspect}"
              publication.identifiers << pub_id
              publication.save

            else
              puts "--- #{identifier} = Unknown\n"
            end

          end
        end
      end
    end
    
    puts "Finished"
  end
end