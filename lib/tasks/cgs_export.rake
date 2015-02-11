require 'fileutils'
require_relative 'ris_writers'
namespace :cgs_export do

  task :ris => :environment do
    ris_dir = File.join(Rails.root, 'tmp', 'exports')
    FileUtils.rm_rf(ris_dir)
    FileUtils.mkdir_p(ris_dir)
    
    work_list.each do |work|
        write_work_to_file(work, File.join(ris_dir, "group_12.ris"))
    end
  end

end

def work_list
  cgs_group = Group.find 12
  works_for_group(cgs_group)
end

def works_for_group(group)
  group.people.collect {|person| person.works}.flatten.uniq
end

def write_work_to_file(work, filename)
  write_klass = case work.type
    when "BookWhole", "Monograph" then RISBook
    when "JournalArticle" then RISJournalArticle
    when "JournalWhole" then RISJournalWhole
    when "Report" then RISReport
    when "Generic", "BookReview" then RISGeneric
    when "BookSection" then RISBookSection
    when "ConferencePaper" then RISConferencePaper
    when "ConferenceProceedingWhole" then RISConferenceProceedingWhole
    when "WebPage" then RISWebPage
    when "RecordingMovingImage" then RISMovingImage
    when "Patent" then RISPatent
  else
    raise RuntimeError, "Unrecognized work type #{type}"
  end
  writer = write_klass.new(work)
  writer.append_to_file(filename)
rescue Exception => e
  puts e.to_s
  puts work.to_yaml
  raise
end





