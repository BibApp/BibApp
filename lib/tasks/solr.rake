# Rake tasks to start/stop Solr for BibApp
#
# This is essentially a modified copy of the solr.rake
# which is distributed alongside acts_as_solr
require 'rubygems'
require 'rake'
require 'net/http'
require 'active_record'
require 'index'
require 'rbconfig'

namespace :solr do

  desc 'Starts Solr. Options accepted: RAILS_ENV=your_env, PORT=XX. Defaults to development if none.'
  task :start => :environment do
    begin
      n = Net::HTTP.new('127.0.0.1', SOLR_PORT)
      n.request_head('/').value

    rescue Net::HTTPServerException #responding
      puts "Port #{SOLR_PORT} already in use" and return

    rescue NoMethodError, Errno::ECONNREFUSED, Errno::EBADF, Errno::ENETUNREACH #not responding

      SOLR_STARTUP_OPTS = "-Dsolr.solr.home=\"#{SOLR_HOME_PATH}\" -Dsolr.data.dir=\"#{SOLR_HOME_PATH}/data/#{Rails.env}\" -Djetty.port=#{SOLR_PORT} #{SOLR_JAVA_OPTS}"

      #If Windows
      if RbConfig::CONFIG['host_os'] =~ /mswin|mingw/
        Dir.chdir(SOLR_PATH) do
          exec "start #{'"'}solr_#{Rails.env}_#{SOLR_PORT}#{'"'} /min java #{SOLR_STARTUP_OPTS} -jar start.jar"
          puts "#{Rails.env} Solr started successfully on #{SOLR_PORT}."
        end
      else #Else if Linux, Mac OSX, etc.
        pid = fork
        unless(pid)
          #child
          #daemonize
          File.umask(0)
          Process.setsid
          Dir.chdir('/')
          STDIN.reopen('/dev/null', 'r')
          STDOUT.reopen('/dev/null', 'w')
          STDERR.reopen('/dev/null', 'w')
          #do work
          Dir.chdir(SOLR_PATH)
          exec "java -DSTOP.PORT=#{SOLR_STOP_PORT} -DSTOP.KEY=bibappsolrstop #{SOLR_STARTUP_OPTS} -jar start.jar"
        end
        #parent
	puts "problem forking child" if pid < 0
        Process.detach(pid)
#        sleep(5)
        File.open("#{SOLR_PATH}/tmp/#{Rails.env}_pid", "w"){ |f| f << pid}
        puts "#{Rails.env} Solr started successfully on #{SOLR_PORT}, pid: #{pid}."
      end
    rescue
      puts "Unexpected Error: #{$!.class.to_s} #{$!}"
      raise
    end
  end

  desc 'OBSOLETE task (used to be necessary for Solr on Windows'
  task :start_win do
    puts "The command 'rake solr:start_win' is now obsolete.  Instead, please use 'rake solr:start' and 'rake solr:stop' to start/stop Solr on Windows."
  end

  desc 'Stops Solr. Specify the environment by using: RAILS_ENV=your_env. Defaults to development if none.'
  task :stop => :environment do
    #If Windows
    if RbConfig::CONFIG['host_os'] =~ /mswin|mingw/
      #taskkill is only available in Windows XP
      exec "taskkill /im java.exe /fi #{'"'}Windowtitle eq solr_#{Rails.env}_#{SOLR_PORT}#{'"'} "
      Rake::Task["solr:destroy_index"].invoke if Rails.env == 'test'
    else #Else if Linux, Mac OSX, etc.
      Dir.chdir(SOLR_PATH) do
        file_path = "#{SOLR_PATH}/tmp/#{Rails.env}_pid"
        if File.exists?(file_path)
          puts "Sending SHUTDOWN command to Solr..."
          fork do
            # We don't want to 'kill' Solr via PID as this doesn't seem
            # to work on Ubuntu, where the PID in this file is always wrong!
            #File.open(file_path, "r") do |f|
            #  pid = f.readline
            #  Process.kill('TERM', pid.to_i)
            #end

            #Stop Solr by sending Jetty the "stop" command on port 8079
            exec "java -DSTOP.PORT=#{SOLR_STOP_PORT} -DSTOP.KEY=bibappsolrstop -jar start.jar --stop"
          end

          Process.wait #wait for forked process to complete
          File.unlink(file_path)
          Rake::Task["solr:destroy_index"].invoke if Rails.env == 'test'
          puts "Solr shutdown successfully."
        else
          puts "Solr is not running. I haven't done anything."
        end
      end #end change dir
    end #end task :stop
  end

  desc 'Remove Solr index'
  task :destroy_index => :environment do
    raise "In production mode. I'm not going to delete the index, sorry." if Rails.env == "production"
    if File.exists?("#{SOLR_HOME_PATH}/data/#{Rails.env}")
      Dir[ SOLR_HOME_PATH + "/data/#{Rails.env}/index/*"].each{|f| File.unlink(f)}
      Dir.rmdir(SOLR_HOME_PATH + "/data/#{Rails.env}/index")
      puts "Index files removed under " + Rails.env + " environment"
    end
  end

  desc 'Optimize Solr index'
  task :optimize_index => :environment do
    puts "\nOptimizing Solr index...\n\n"
    Index.optimize_index
     puts "Finished optimization!"
  end

  desc 'Refresh Solr index'
  task :refresh_index => :environment do
    puts "\nRe-indexing all BibApp Works in Solr...\n\n"
    puts "**** Depending on the number of works, \n"
    puts "**** this may take a long time.\n\n"

    start_time = Time.now
    puts "Start time: #{start_time.localtime}"

    #Call index_all, which re-indexes *everything* in BibApp
    Index.index_all

    end_time = Time.now
    puts "End time: #{end_time.localtime}"

    #Caculate total indexing time
    total = end_time.to_i - start_time.to_i
    time = "#{total.div(60).to_s} minutes" if total >=120
    time = "#{total.div(60).to_s} minute, #{total.remainder(60).to_s} seconds" if total >= 60 and total < 120
    time = "#{(total).to_s} seconds" if total < 60

    puts "Finished indexing!  Total indexing time: #{time}"
  end

  desc 'Refresh Solr Spelling index'
  task :refresh_spelling_suggestions => :environment do
    puts "\nRefreshing BibApp spelling suggestions in Solr...\n"

    #Call build_spelling_suggestions
    Index.build_spelling_suggestions

    puts "Finished!"
  end

end
