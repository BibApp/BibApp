namespace :sword_client do

  desc 'Parses SWORD service document (based on configurations in "#{RAILS_ROOT}/config/sword.yml")
        and writes the resulting YAML file to #{RAILS_ROOT}/tmp/ \n
        This is useful for debugging problems or ensuring that the Service Document is being parsed fully.'
  task :test_parse_service_doc => :environment do
    
    #Only continue if SWORD client is configured properly
    if SwordClient.configured?

      client = SwordClient.new

      parsed_service_doc = client.parsed_service_document

      #Write output to [rails_app]/tmp/ directory
      #(File will be named "parsed_service_doc.yml")
      File.open("#{RAILS_ROOT}/tmp/parsed_service_doc.yml", "w"){ |f| f << YAML::dump(parsed_service_doc)}
      puts "Results written to #{RAILS_ROOT}/tmp/parsed_service_doc.yml" and return
    else
      puts "Sword Client is not configured" and return
    end
  end


  desc 'Parses the test fixture POST responses in
        [sword-client]/test/fixtures/post-response/*
        and writes the resulting YAML file to #{RAILS_ROOT}/tmp/ \n
        This is useful for debugging problems or ensuring that different types of POST responses are being parsed fully.'
  task :test_parse_post_fixtures => :environment do

    #Only continue if SWORD client is configured properly
    if SwordClient.configured?

      #Take all the Test fixtures and run them through the response parser
      Dir["#{File.expand_path(File.dirname(__FILE__))}/../test/fixtures/post-response/*"].each do |filepath|

        #Read the file into a string
        if filepath.respond_to? :read
          str = filepath.read
        elsif File.readable?(filepath)
          str = File.read(filepath)
        end
        
        #parse the file into a hash
        response_hash = SwordClient::Response.post_response_to_hash(str)

        #Write output to [rails_app]/tmp/ directory
        #(File will be of same name, but with ".yml" appended to it)
        File.open("#{RAILS_ROOT}/tmp/#{File.basename(filepath)}.yml", "w"){ |f| f << YAML::dump(response_hash)}
        puts "Results written to #{RAILS_ROOT}/tmp/#{File.basename(filepath)}.yml" and return
      end
    else
      puts "Sword Client is not configured" and return
    end
  end


  desc 'Performs a test POST of a file (based on configurations in "#{RAILS_ROOT}/config/sword.yml")
        and writes the resulting response to YAML file in [rails-app]/tmp/ \n
        This is useful for debugging problems or ensuring that the POST response is being parsed fully.'
  task :test_post_file => :environment do

    #Only continue if SWORD client is configured properly
    if SwordClient.configured?

      client = SwordClient.new

      #Post the sword-example.zip file to the specified Default Collection in 'sword.yml'
      #  Also sets the 'no_op' flag which means the package isn't actually deposited by the server.
      post_response_doc = client.post_file("#{File.expand_path(File.dirname(__FILE__))}/../test/fixtures/sword-example.zip",nil,{:no_op=>true})

      #parse the file into a hash
      response_hash = SwordClient::Response.post_response_to_hash(post_response_doc)

      #Write output to [rails_app]/tmp/ directory
      #(File will be named "parsed_service_doc.yml")
      File.open("#{RAILS_ROOT}/tmp/parsed_post_file.yml", "w"){ |f| f << YAML::dump(response_hash)}
      puts "Results written to #{RAILS_ROOT}/tmp/parsed_post_file.yml"
    else
      puts "Sword Client is not configured" and return
    end
  end




end
