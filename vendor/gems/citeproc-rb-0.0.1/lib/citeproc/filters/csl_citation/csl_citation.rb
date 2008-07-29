#  == Synopsis
#
# Simple citation model
#
#  == Author
#
#  Liam Magee
#
#  == Copyright
#
#  Copyright (c) 2008, Liam Magee.
#  Licensed under the same terms as Ruby - see http://www.ruby-lang.org/en/LICENSE.txt.
#
#

module CSL
  
  # ---------- Classes -----------

  
  # Defines the Citation class
  class Citation
    attr_accessor :type
    attr_accessor :title, :container_title, :collection_title
    attr_accessor :publisher, :publisher_place
    attr_accessor :event, :event_place
    attr_accessor :pages, :version, :volume, :number_of_volumes, :issue
    attr_accessor :medium, :status, :edition, :note, :annote, :abstract
    attr_accessor :keyword, :number
    attr_accessor :archive, :archive_location, :archive_place
    attr_accessor :url, :doi, :isbn
    attr_accessor :date_issued, :date_accessed
    attr_accessor :contributors
    
    def initialize
      @contributors = []
    end
    
    def method_missing(name, *args)
      case name.to_s
      when "locator"
        return resolve_locator
      else
        ""
      end
    end
    
    def authors=(authors)
      add_contributors(authors, "author")
    end
    
    def authors
      contributors("author")
    end
    
    def editors=(editors)
      add_contributors(editors, "editor")
    end
    
    def editors
      contributors("editor")
    end
    
    def translators=(translators)
      add_contributors(translators, "translator")
    end
    
    def translators
      translators("translator")
    end
    
    def contributors(role = nil, sort_key = nil)
      results = @contributors.collect{|c| c if c.role and c.role == role }.compact
      if sort_key
        if sort_key == "first"
          results.sort!{ |a, b| a.given_name <=> b.given_name }
        else
          results.sort!{ |a, b| a.name <=> b.name }
        end
      end
      results
    end
    
    
    def add_contributor_name(name, role = "author")
      c = ContributingAgent.new
      c.name = name
      c.role = role
      add_contributor(c)
    end
    
    def add_contributor(contributor)
      @contributors << contributor if contributor.is_a?(ContributingAgent)
    end
    
    def add_contributors(contribs, role = "author")
      contribs.each do |contrib|  
        c = ContributingAgent.new
        c.role = role
        contrib.each do |key, value|
          c.send("#{key}=", value)
        end
        @contributors << c
      end
    end
    
    def resolve_locator
      result = nil
      result ||= self.issue
      result ||= self.volume
      result ||= self.url
      result
    end
  end

  
  # Defines the Citation class
  class ContributingAgent
    attr_accessor :name, :role

    def initialize(role = "author", name = nil)
      @role = role
      @name = name
    end
    
    def given_name
      # brittle....
      name.split(/, /)[1]
    end
    
    def family_name
      # brittle....
      name.split(/, /)[0]
    end
  end

end
