# Rake tasks to preform batch operations on works in BibApp
#
require 'rubygems'
require 'rake'

namespace :works_helper do

  desc "Deletes a batch of works for a person. Ex: 'rake works_helper:batch_delete person_id=7'."
  task :batch_destroy => :environment do
    if ENV['person_id']
      @works = Person.find("#{ENV['person_id']}").works
      @works.each do |work|
        work.destroy
      end
    else
      puts "Usage example: 'rake works_helper:batch_delete person_id=7'"
    end
  end

  desc "Deletes all works"
  task :batch_destroy_all => :environment do
    @works = Work.all
    @works.each do |work|
      work.destroy
    end
  end

end