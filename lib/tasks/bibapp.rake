# Rake tasks to start/stop BibApp services

namespace :bibapp do
  desc 'Starts all BibApp services: solr, delayed_jobs, passenger'
  task :start => :environment do
    puts "\n\n== Starting all BibApp services: solr, delayed_jobs, passenger"

    begin
      # Start Solr
      puts "* Starting - Solr."
      Rake::Task[ "solr:start"].execute
    rescue
      RuntimeError
      puts "### ERROR - Starting - Solr."
    end

    begin
      # Start Delayed Job
      puts "\n\n* Starting - Delayed Job."

      # Create the tmp/pids directory if it's not there
      if File.exists?("#{Rails.root}/tmp/pids")
        sh "script/delayed_job start #{Rails.env}"
      else
        sh "mkdir #{Rails.root}/tmp/pids"
        sleep(2)
        sh "script/delayed_job start #{Rails.env}"
      end
    rescue
      RuntimeError
      puts "### ERROR - Starting - Delayed Job."
    end

    begin
      # Spin passenger
      puts "\n\n* Starting - Passenger."
      sh "touch tmp/restart.txt"
    rescue
      RuntimeError
      puts "### ERROR - Starting - Passenger."
    end

    puts "Finished bibapp:start"
  end

  desc 'Stop all BibApp services: solr, delayed_jobs, passenger'
  task :stop => :environment do
    begin
      # Stop Solr
      Rake::Task[ "solr:stop"].execute

      # Stop Delayed Job
      sh "script/delayed_job stop #{Rails.env}"

      # Spin passenger
      sh "touch tmp/restart.txt"
    end

    puts "Finished bibapp:stop"
  end

  desc 'Restart all BibApp services: solr, delayed_jobs, passenger'
  task :restart => :environment do
    begin
      # Run rake bibapp:stop
      Rake::Task[ "bibapp:stop"].execute

      # Run rake bibapp:start
      Rake::Task[ "bibapp:start"].execute
    end
  end
end