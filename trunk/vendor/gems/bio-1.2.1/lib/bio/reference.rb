#
# = bio/reference.rb - Journal reference classes
#
# Copyright::   Copyright (C) 2001, 2006
#               Toshiaki Katayama <k@bioruby.org>,
#               Ryan Raaum <ryan@raaum.org>
# License::     The Ruby License
#
# $Id: reference.rb,v 1.24 2007/04/05 23:35:39 trevor Exp $
#

module Bio

  # = DESCRIPTION
  #
  # A class for journal reference information.
  #
  # = USAGE
  # 
  #    hash = {'authors' => [ "Hoge, J.P.", "Fuga, F.B." ], 
  #            'title' => "Title of the study.",
  #            'journal' => "Theor. J. Hoge", 
  #            'volume' => 12, 
  #            'issue' => 3, 
  #            'pages' => "123-145",
  #            'year' => 2001, 
  #            'pubmed' => 12345678, 
  #            'medline' => 98765432, 
  #            'abstract' => "Hoge fuga. ...",
  #            'url' => "http://example.com", 
  #            'mesh' => [], 
  #            'affiliations' => []}
  #    ref = Bio::Reference.new(hash)
  #
  #    # Formats in the BiBTeX style.
  #    ref.format("bibtex")
  #    
  #    # Short-cut for Bio::Reference#format("bibtex")
  #    ref.bibtex
  #
  class Reference

    # Author names in an Array, [ "Hoge, J.P.", "Fuga, F.B." ].
    attr_reader :authors

    # String with title of the study
    attr_reader :title

    # String with journal name
    attr_reader :journal

    # volume number (typically Fixnum)
    attr_reader :volume
    
    # issue number (typically Fixnum)
    attr_reader :issue

    # page range (typically String, e.g. "123-145")
    attr_reader :pages

    # year of publication (typically Fixnum)
    attr_reader :year

    # pubmed identifier (typically Fixnum)
    attr_reader :pubmed

    # medline identifier (typically Fixnum)
    attr_reader :medline
    
    # Abstract text in String.
    attr_reader :abstract

    # An URL String.
    attr_reader :url

    # MeSH terms in an Array.
    attr_reader :mesh

    # Affiliations in an Array.
    attr_reader :affiliations

    # Create a new Bio::Reference object from a Hash of values. 
    # Data is extracted from the values for keys:
    #
    # * authors - expected value: Array of Strings
    # * title - expected value: String
    # * journal - expected value: String
    # * volume - expected value: Fixnum or String
    # * issue - expected value: Fixnum or String
    # * pages - expected value: String
    # * year - expected value: Fixnum or String
    # * pubmed - expected value: Fixnum or String
    # * medline - expected value: Fixnum or String
    # * abstract - expected value: String
    # * url - expected value: String
    # * mesh - expected value: Array of Strings
    # * affiliations - expected value: Array of Strings
    #
    #
    #    hash = {'authors' => [ "Hoge, J.P.", "Fuga, F.B." ], 
    #            'title' => "Title of the study.",
    #            'journal' => "Theor. J. Hoge", 
    #            'volume' => 12, 
    #            'issue' => 3, 
    #            'pages' => "123-145",
    #            'year' => 2001, 
    #            'pubmed' => 12345678, 
    #            'medline' => 98765432, 
    #            'abstract' => "Hoge fuga. ...",
    #            'url' => "http://example.com", 
    #            'mesh' => [], 
    #            'affiliations' => []}
    #    ref = Bio::Reference.new(hash)
    # ---
    # *Arguments*:
    # * (required) _hash_: Hash
    # *Returns*:: Bio::Reference object
    def initialize(hash)
      hash.default = ''
      @authors  = hash['authors'] # [ "Hoge, J.P.", "Fuga, F.B." ]
      @title    = hash['title']   # "Title of the study."
      @journal  = hash['journal'] # "Theor. J. Hoge"
      @volume   = hash['volume']  # 12
      @issue    = hash['issue']   # 3
      @pages    = hash['pages']   # 123-145
      @year     = hash['year']    # 2001
      @pubmed   = hash['pubmed']  # 12345678
      @medline  = hash['medline'] # 98765432
      @abstract = hash['abstract']
      @url      = hash['url']
      @mesh     = hash['mesh']
      @affiliations = hash['affiliations']
      @authors = [] if @authors.empty?
      @mesh    = [] if @mesh.empty?
      @affiliations = [] if @affiliations.empty?
    end

    # Formats the reference in a given style.
    #
    # Styles:
    # 0. nil - general
    # 1. endnote - Endnote
    # 2. bibitem - Bibitem (option available)
    # 3. bibtex - BiBTeX (option available)
    # 4. rd - rd (option available)
    # 5. nature - Nature (option available)
    # 6. science - Science
    # 7. genome_biol - Genome Biology
    # 8. genome_res - Genome Research
    # 9. nar - Nucleic Acids Research
    # 10. current - Current Biology
    # 11. trends - Trends in *
    # 12. cell - Cell Press
    #
    # See individual methods for details. Basic usage is:
    #
    #   # ref is Bio::Reference object
    #   # using simplest possible call (for general style)
    #   puts ref.format
    #   
    #   # output in Nature style
    #   puts ref.format("nature")      # alternatively, puts ref.nature
    #
    #   # output in Nature short style (see Bio::Reference#nature)
    #   puts ref.format("nature",true) # alternatively, puts ref.nature(true)
    # ---
    # *Arguments*:
    # * (optional) _style_: String with style identifier
    # * (optional) _option_: Option for styles accepting one
    # *Returns*:: String
    def format(style = nil, option = nil)
      case style
      when 'endnote'
        return endnote
      when 'bibitem'
        return bibitem(option)
      when 'bibtex'
        return bibtex(option)
      when 'rd'
        return rd(option)
      when /^nature$/i
        return nature(option)
      when /^science$/i
        return science
      when /^genome\s*_*biol/i
        return genome_biol
      when /^genome\s*_*res/i
        return genome_res
      when /^nar$/i
        return nar
      when /^current/i
        return current
      when /^trends/i
        return trends
      when /^cell$/i
        return cell
      else
        return general
      end
    end

    # Returns reference formatted in the Endnote style.
    #
    #   # ref is a Bio::Reference object
    #   puts ref.endnote
    #
    #     %0 Journal Article
    #     %A Hoge, J.P.
    #     %A Fuga, F.B.
    #     %D 2001
    #     %T Title of the study.
    #     %J Theor. J. Hoge
    #     %V 12
    #     %N 3
    #     %P 123-145
    #     %M 12345678
    #     %U http://www.ncbi.nlm.nih.gov/entrez/query.fcgi?cmd=Retrieve&db=PubMed&dopt=Citation&list_uids=12345678
    #     %X Hoge fuga. ...
    # ---
    # *Returns*:: String
    def endnote
      lines = []
      lines << "%0 Journal Article"
      @authors.each do |author|
        lines << "%A #{author}"
      end
      lines << "%D #{@year}" unless @year.to_s.empty?
      lines << "%T #{@title}" unless @title.empty?
      lines << "%J #{@journal}" unless @journal.empty?
      lines << "%V #{@volume}" unless @volume.to_s.empty?
      lines << "%N #{@issue}" unless @issue.to_s.empty?
      lines << "%P #{@pages}" unless @pages.empty?
      lines << "%M #{@pubmed}" unless @pubmed.to_s.empty?
      if @pubmed
        cgi = "http://www.ncbi.nlm.nih.gov/entrez/query.fcgi"
        opts = "cmd=Retrieve&db=PubMed&dopt=Citation&list_uids"
        @url = "#{cgi}?#{opts}=#{@pubmed}"
      end
      lines << "%U #{@url}" unless @url.empty?
      lines << "%X #{@abstract}" unless @abstract.empty?
      @mesh.each do |term|
        lines << "%K #{term}"
      end
      lines << "%+ #{@affiliations.join(' ')}" unless @affiliations.empty?
      return lines.join("\n")
    end

    # Returns reference formatted in the bibitem style
    #
    #   # ref is a Bio::Reference object
    #   puts ref.bibitem
    #
    #     \bibitem{PMID:12345678}
    #     Hoge, J.P., Fuga, F.B.
    #     Title of the study.,
    #     {\em Theor. J. Hoge}, 12(3):123--145, 2001.
    # ---
    # *Returns*:: String
    def bibitem(item = nil)
      item  = "PMID:#{@pubmed}" unless item
      pages = @pages.sub('-', '--')
      return <<-"END".collect {|line| line.strip}.join("\n")
        \\bibitem{#{item}}
        #{@authors.join(', ')}
        #{@title},
        {\\em #{@journal}}, #{@volume}(#{@issue}):#{pages}, #{@year}.
      END
    end

    # Returns reference formatted in the BiBTeX style.
    #
    #   # ref is a Bio::Reference object
    #   puts ref.bibtex
    #
    #     @article{PMID:12345678,
    #       author  = {Hoge, J.P. and Fuga, F.B.},
    #       title   = {Title of the study.},
    #       journal = {Theor. J. Hoge},
    #       year    = {2001},
    #       volume  = {12},
    #       number  = {3},
    #       pages   = {123--145},
    #     }
    #
    #   # using a different section (e.g. "book")
    #   # (but not really configured for anything other than articles)
    #   puts ref.bibtex("book")
    #
    #     @book{PMID:12345678,
    #       author  = {Hoge, J.P. and Fuga, F.B.},
    #       title   = {Title of the study.},
    #       journal = {Theor. J. Hoge},
    #       year    = {2001},
    #       volume  = {12},
    #       number  = {3},
    #       pages   = {123--145},
    #     }    
    # ---
    # *Arguments*:
    # * (optional) _section_: BiBTeX section as String
    # *Returns*:: String
    def bibtex(section = nil)
      section = "article" unless section
      authors = authors_join(' and ', ' and ')
      pages   = @pages.sub('-', '--')
      return <<-"END".gsub(/\t/, '')
        @#{section}{PMID:#{@pubmed},
          author  = {#{authors}},
          title   = {#{@title}},
          journal = {#{@journal}},
          year    = {#{@year}},
          volume  = {#{@volume}},
          number  = {#{@issue}},
          pages   = {#{pages}},
        }
      END
    end

    # Returns reference formatted in a general/generic style.
    #
    #   # ref is a Bio::Reference object
    #   puts ref.general
    #
    #     Hoge, J.P., Fuga, F.B. (2001). "Title of the study." Theor. J. Hoge 12:123-145.
    # ---
    # *Returns*:: String
    def general
      authors = @authors.join(', ')
      "#{authors} (#{@year}). \"#{@title}\" #{@journal} #{@volume}:#{@pages}."
    end

    # Return reference formatted in the RD style.
    #
    #   # ref is a Bio::Reference object
    #   puts ref.rd
    #
    #     == Title of the study.
    #     
    #     * Hoge, J.P. and Fuga, F.B.
    #     
    #     * Theor. J. Hoge 2001 12:123-145 [PMID:12345678]
    #     
    #     Hoge fuga. ...
    #
    # An optional string argument can be supplied, but does nothing.
    # ---
    # *Arguments*:
    # * (optional) str: String (default nil)
    # *Returns*:: String
    def rd(str = nil)
      @abstract ||= str
      lines = []
      lines << "== " + @title
      lines << "* " + authors_join(' and ')
      lines << "* #{@journal} #{@year} #{@volume}:#{@pages} [PMID:#{@pubmed}]"
      lines << @abstract
      return lines.join("\n\n")
    end

    # Formats in the Nature Publishing Group 
    # (http://www.nature.com) style.
    #
    #   # ref is a Bio::Reference object
    #   puts ref.nature
    #
    #     Hoge, J.P. & Fuga, F.B. Title of the study. Theor. J. Hoge 12, 123-145 (2001).
    #
    #   # optionally, output short version
    #   puts ref.nature(true)  # or puts ref.nature(short=true)
    #
    #     Hoge, J.P. & Fuga, F.B. Theor. J. Hoge 12, 123-145 (2001).
    # ---
    # *Arguments*:
    # * (optional) _short_: Boolean (default false)
    # *Returns*:: String
    def nature(short = false)
      if short
        if @authors.size > 4
          authors = "#{@authors[0]} et al."
        elsif @authors.size == 1
          authors = "#{@authors[0]}"
        else
          authors = authors_join(' & ')
        end
        "#{authors} #{@journal} #{@volume}, #{@pages} (#{@year})."
      else
        authors = authors_join(' & ')
        "#{authors} #{@title} #{@journal} #{@volume}, #{@pages} (#{@year})."
      end
    end

    # Returns reference formatted in the 
    # Science[http://www.sciencemag.org] style.
    #
    #   # ref is a Bio::Reference object
    #   puts ref.science
    #
    #     J.P. Hoge, F.B. Fuga, Theor. J. Hoge 12 123 (2001).
    # ---
    # *Returns*:: String
    def science
      if @authors.size > 4
        authors = rev_name(@authors[0]) + " et al."
      else
        authors = @authors.collect {|name| rev_name(name)}.join(', ')
      end
      page_from, = @pages.split('-')
      "#{authors}, #{@journal} #{@volume} #{page_from} (#{@year})."
    end

    # Returns reference formatted in the Genome Biology 
    # (http://genomebiology.com) style.
    #
    #   # ref is a Bio::Reference object
    #   puts ref.genome_biol
    #
    #     Hoge JP, Fuga FB: Title of the study. Theor J Hoge 2001, 12:123-145.
    # ---
    # *Returns*:: String
    def genome_biol
      authors = @authors.collect {|name| strip_dots(name)}.join(', ')
      journal = strip_dots(@journal)
      "#{authors}: #{@title} #{journal} #{@year}, #{@volume}:#{@pages}."
    end
    
    # Returns reference formatted in the Current Biology 
    # (http://current-biology.com) style. (Same as the Genome Biology style)
    #
    #   # ref is a Bio::Reference object
    #   puts ref.current
    #
    #     Hoge JP, Fuga FB: Title of the study. Theor J Hoge 2001, 12:123-145.
    # ---
    # *Returns*:: String
    def current 
      self.genome_biol
    end

    # Returns reference formatted in the Genome Research 
    # (http://genome.org) style.
    #
    #   # ref is a Bio::Reference object
    #   puts ref.genome_res
    #
    #     Hoge, J.P. and Fuga, F.B. 2001.
    #       Title of the study. Theor. J. Hoge 12: 123-145.
    # ---
    # *Returns*:: String
    def genome_res
      authors = authors_join(' and ')
      "#{authors} #{@year}.\n  #{@title} #{@journal} #{@volume}: #{@pages}."
    end

    # Returns reference formatted in the Nucleic Acids Reseach 
    # (http://nar.oxfordjournals.org) style.
    #
    #   # ref is a Bio::Reference object
    #   puts ref.nar
    #
    #     Hoge, J.P. and Fuga, F.B. (2001) Title of the study. Theor. J. Hoge, 12, 123-145.
    # ---
    # *Returns*:: String
    def nar
      authors = authors_join(' and ')
      "#{authors} (#{@year}) #{@title} #{@journal}, #{@volume}, #{@pages}."
    end

    # Returns reference formatted in the 
    # CELL[http://www.cell.com] Press style.
    #
    #   # ref is a Bio::Reference object
    #   puts ref.cell
    #
    #     Hoge, J.P. and Fuga, F.B. (2001). Title of the study. Theor. J. Hoge 12, 123-145.
    # ---
    # *Returns*:: String
    def cell
      authors = authors_join(' and ')
      "#{authors} (#{@year}). #{@title} #{@journal} #{@volume}, #{pages}."
    end
    
    # Returns reference formatted in the 
    # TRENDS[http://www.trends.com] style.
    #
    #   # ref is a Bio::Reference object
    #   puts ref.trends
    #
    #     Hoge, J.P. and Fuga, F.B. (2001) Title of the study. Theor. J. Hoge 12, 123-145
    # ---
    # *Returns*:: String
    def trends
      if @authors.size > 2
        authors = "#{@authors[0]} et al."
      elsif @authors.size == 1
        authors = "#{@authors[0]}"
      else
        authors = authors_join(' and ')
      end
      "#{authors} (#{@year}) #{@title} #{@journal} #{@volume}, #{@pages}"
    end


    private

    def strip_dots(data)
      data.tr(',.', '') if data
    end

    def authors_join(amp, sep = ', ')
      authors = @authors.clone
      if authors.length > 1
        last = authors.pop
        authors = authors.join(sep) + "#{amp}" + last
      elsif authors.length == 1
        authors = authors.pop
      else
        authors = ""
      end
    end

    def rev_name(name)
      if name =~ /,/
        name, initial = name.split(/,\s+/)
        name = "#{initial} #{name}"
      end
      return name
    end

  end

  # = DESCRIPTION
  #
  # A container class for Bio::Reference objects.
  #
  # = USAGE
  #
  #   refs = Bio::References.new
  #   refs.append(Bio::Reference.new(hash))
  #   refs.each do |reference|
  #     ...
  #   end
  #
  class References

    # Array of Bio::Reference objects
    attr_accessor :references

    # Create a new Bio::References object
    # 
    #   refs = Bio::References.new
    # ---
    # *Arguments*:
    # * (optional) __: Array of Bio::Reference objects
    # *Returns*:: Bio::References object
    def initialize(ary = [])
      @references = ary
    end


    # Add a Bio::Reference object to the container.
    #
    #   refs.append(reference)
    # ---
    # *Arguments*:
    # * (required) _reference_: Bio::Reference object
    # *Returns*:: current Bio::References object
    def append(reference)
      @references.push(reference) if reference.is_a? Reference
      return self
    end

    # Iterate through Bio::Reference objects.
    #
    #   refs.each do |reference|
    #     ...
    #   end
    # ---
    # *Block*:: yields each Bio::Reference object
    def each
      @references.each do |reference|
        yield reference
      end
    end

  end

end

