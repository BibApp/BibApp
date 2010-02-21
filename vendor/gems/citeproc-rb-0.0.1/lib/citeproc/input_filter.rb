#  == Synopsis
#
#  The InputFilter is a generic class for converting some form of citation data into
#  variables which can be used by the Citeproc system.
#  
#  NB: The 'canonical' input filter is the BiblioInputFilter, which takes an object model
#  from the Bibliontology as input. As the Bibliontology is intended as an abstract
#  'core' ontology, designed to represent a large number of potential citation structures,
#  it may make the InputFilter approach redundant. For example, rather than converting
#  BibTeX directly to the internal variable structures of Citeproc, it may be preferrable
#  to convert BibTeX to Bibliontology first. Hence, please subclass InputFilter with care...
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

require 'open-uri'

module Citeproc
  
  # Base class, defining services expected of a particular input format.
  # Typically, implementations will parse a citation source, and deliver a series of values
  # required by the CSL Formatter.
  # Note: this class should never be instantiated directly - it acts like an abstract class (should be a module?)
  class InputFilter
    
    attr_accessor :citations
    
    def initialize
      @citations = {}
    end

    # Parses the +source+, and calls the load_model method with the results and +params+.
    def parse(source, params)
      begin
        open(source, 'rb') do |f|
          load_citations(f, params)
        end
      rescue
        load_citations(source,params)
      end
    end
    
    # Loads the model - needs to be implemented 
    def load_citations(source, params); end


    
    
    # Citation iterator
    def each_citation
      @citations.values.each do |citation|
        @current_citation = citation
        yield citation
      end
    end
    
    # Citation iterator
    def each_sorted_citation(keyset)
      sorted_citations(keyset).each do |citation|
        @current_citation = citation
        yield citation
      end
    end
    
    
    def sorted_citations(keyset)
      keyset.sort do |a, b|  
        result = 0
        for i in (1..a.length - 1) 
          result = a[i] <=> b[i]
          break if result != 0
        end
        result
      end.collect {|keys| keys[0]}
    end
    
    
    

    def extract_contributor(role, sort_by = nil); end
    
    # Tests the document class, and returns the corresponding CSL type
    def resolve_type; end

    def extract_date(variable); end

    def extract_locator_label(label); end

    def extract_page_label(label); end

    def extract_variable(variable); end

  end
end
