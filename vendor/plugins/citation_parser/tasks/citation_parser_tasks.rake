namespace :citation_parser do

  desc 'Parses each of the Test Fixtures, and dumps them to YAML files in [rails-app]/tmp/ \n
        This is useful for debugging or auto-generating fixtures for citation_importer plugin.'
  task :test_dump => :environment do
    
    parser = CitationParser.new
    
    #Take all the Test fixtures and run them through a parser
    Dir["#{File.expand_path(File.dirname(__FILE__))}/../test/fixtures/*"].each do |filepath| 
      
      #Read the file
      if filepath.respond_to? :read
        str = filepath.read
      elsif File.readable?(filepath)
        str = File.read(filepath)
      end
      
      #Parse into an output hash
      pcites = parser.parse(str)

      #Write output to [rails_app]/tmp/ directory
      #(File will be of same name, but with ".yml" appended to it)
      File.open("#{File.expand_path(File.dirname(__FILE__))}/../../../../tmp/#{File.basename(filepath)}.yml", "w"){ |f| f << YAML::dump(pcites)}
    end
    
  end
end