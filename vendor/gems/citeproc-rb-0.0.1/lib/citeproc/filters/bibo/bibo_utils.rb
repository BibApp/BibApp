#  == Synopsis
#
# Utility methods for generating, loading and storing Bibliontology models
#
#  == Author
#
#  Liam Magee
#
#  == Copyright
#
#  Copyright (c) 2007, Liam Magee.
#  Licensed under the same terms as Ruby - see http://www.ruby-lang.org/en/LICENSE.txt.
#
 
require 'yaml'

module Bibo
  module BiboUtils
    include Bibo


    # Save/load methods for YAML

    # Load the sample document from a YAML file
    def self.from_yaml(file)
      YAML.load(File.new(file))
    end


    # Load the sample document from a YAML file
    def self.from_yaml(file, document)
      YAML.dump(document, File.new(file, "w+"))
    end


    # Load the sample document from a RDF file
    def self.rdf_model(file, name = "rdfxml")
      require 'rdf/redland'
      model = Redland::Model.new
      parser = Redland::Parser.new(name, "")
      parser.parse_into_model(model, file)
      model
    end


    # Load the sample document from a RDF file
    def self.from_rdf(file, name = "rdfxml")
      require 'rdf/redland'
      model = rdf_model(file, name)
      model.triples do |s, p, o|
        case p.to_s
        when /type/
          os = o.to_s
          #puts os[os.rindex('/') + 1..os.rindex(']') - 1]
        else
        end
      end 
      model
    end



    # Provide a command-line interface to the parser
    if __FILE__ == $0
      if ARGV[0] and ARGV[1]
        if (ARGV[0] == '-l' or ARGV[0] == '--load')
          puts from_yaml(ARGV[1]).to_yaml
        else
          puts "Not doing anything."
          to_yaml(ARGV[1])
        end
      end
    end
  end
end
