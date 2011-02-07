namespace :citation_importer do

  desc 'Translates each of the Test Fixtures, and dumps the result to YAML files in [rails-app]/tmp/ \n
        This is useful for debugging the citation_importer plugin.'
  task :test_dump => :environment do
    
    importer = CitationImporter.new
    
    #Take all the Test fixtures and run them through an importer
    Dir["#{File.expand_path(File.dirname(__FILE__))}/../test/fixtures/*"].each do |filepath| 
      
      #Read the file as an already parsed citation
      if filepath.respond_to? :read
        parsedCites = YAML::load(filepath.read)
      elsif File.readable?(filepath)
        parsedCites = YAML::load(File.read(filepath))
      end
     
      #Transform to valid BibApp attribute hashes
      hashes = importer.citation_attribute_hashes(parsedCites)

      #Write output to [rails_app]/tmp/ directory
      #(File will be of same base name (with old suffix removed) and ".bibapp.yml" appended to it)
      File.open("#{File.expand_path(File.dirname(__FILE__))}/../../../../tmp/#{File.basename(filepath, '.*')}.bibapp.yml", "w"){ |f| f << YAML::dump(hashes)}
    end
    
  end
end