# Rake tasks to start/stop BibApp services

namespace :bibapp do
  desc 'Starts all BibApp services: solr, delayed_jobs, passenger'
  task :start => :environment do
    puts "\n\n== Starting all BibApp services: solr, delayed_jobs, passenger"

    begin
      # Start Solr
      puts "* Starting - Solr."
      Rake::Task["solr:start"].execute
    rescue RuntimeError
      puts "### ERROR - Starting - Solr."
    end

    begin
      # Start Delayed Job
      puts "\n\n* Starting - Delayed Job."

      # Create the tmp/pids directory if it's not there
      unless File.exists?(delayed_job_pid_dir)
        sh "mkdir #{delayed_job_pid_dir}"
        sleep(2)
      end
      ENV['RAILS_ENV'] = Rails.env
      sh "script/delayed_job -p #{Rails.env} --pid-dir=#{delayed_job_pid_dir} start"
    rescue RuntimeError
      puts "### ERROR - Starting - Delayed Job."
    end

    begin
      # Spin passenger
      puts "\n\n* Starting - Passenger."
      sh "touch tmp/restart.txt"
    rescue RuntimeError
      puts "### ERROR - Starting - Passenger."
    end

    puts "Finished bibapp:start"
  end

  desc 'Stop all BibApp services: solr, delayed_jobs, passenger'
  task :stop => :environment do
    begin
      # Stop Solr
      Rake::Task["solr:stop"].execute

      # Stop Delayed Job
      ENV['RAILS_ENV'] = Rails.env
      sh "script/delayed_job -p #{Rails.env} --pid-dir=#{delayed_job_pid_dir} stop"

      # Spin passenger
      sh "touch tmp/restart.txt"
    end

    puts "Finished bibapp:stop"
  end

  desc 'Restart all BibApp services: solr, delayed_jobs, passenger'
  task :restart => :environment do
    begin
      # Run rake bibapp:stop
      Rake::Task["bibapp:stop"].execute

      # Run rake bibapp:start
      Rake::Task["bibapp:start"].execute
    end
  end
end

def delayed_job_pid_dir()
  "#{Rails.root}/tmp/delayed_job_#{Rails.env}_pids"
end