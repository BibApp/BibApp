class RefworksXmlParser < CitationParser
  require 'hpricot'
  require 'htmlentities'
    
  # Perform our initial parse of Citation Data,
  # using Hpricot to parse the Refworks XML format
  def parse(data)
    Hpricot.buffer_size = 204800
    xml = Hpricot.XML(data)
    row_count = (xml/'z:row').collect{|ref| ref.to_s}
    if row_count.size < 1
      return nil
    end
  
    (xml/'z:row').each { |ref|
      # add the citation to the database
      c = ParsedCitation.new(:refworks_xml)

      # escape and parse troublesome keywords
      keywords = HTMLEntities.new
      ref[:Keyword] = keywords.decode(ref[:Keyword].to_s)
      user_two = HTMLEntities.new
      ref[:User2] = user_two.decode(ref[:User2].to_s)
      c.properties = param_hash(ref)
      @citations << c
    }
    
    @citations.each do |c|
      puts("\n\nCitation: #{c.inspect}\n\n")
    end
    
    puts("\nCitations Size: #{@citations.size}\n")
    puts("\nRefworksParser says:#{@citations.each{|c| c.inspect}}\n")
    
    #Return @citations
    @citations
  end
  
  def param_hash(xml)

    return {
      :ref_type => xml[:RefType].to_a,
      :author_primary => xml[:AuthorPrimary].split("|"),
      :author_secondary => xml[:AuthorSecondary].split("|"),
      :title_primary => xml[:TitlePrimary].to_a,
      :title_secondary => xml[:TitleSecondary].to_a,
      :title_tertiary => xml[:TitleTertiary].to_a,
      :keyword => xml[:Keyword].split(/\||;/).each{|k| k.strip!},
      :pub_year => xml[:PubYear].to_a,
      :periodical_full => xml[:PeriodicalFull].to_a,
      :periodical_abbrev => xml[:PeriodicalAbbrev].to_a,
      :volume => xml[:Volume].to_a,
      :issue => xml[:Issue].to_a,
      :start_page => xml[:StartPage].to_a,
      :other_pages => xml[:OtherPages].to_a,
      :edition =>  xml[:Edition].to_a,
      :publisher => xml[:Publisher].to_a,
      :place_of_publication => xml[:PlaceOfPublication].to_a,
      :issn_isbn => xml[:ISSN_ISBN].to_a,
      :availability => xml[:Availability].to_a,
      :author_address_affiliations => xml[:Author_Address_Affiliation].to_a,
      :accession_number => xml[:AccessionNumber].to_a,
      :language => xml[:Language].to_a,
      :classification => xml[:Classification].to_a,
      :subfile_database => xml[:SubFile_Database].to_a,
      :original_foreign_title => xml[:OriginalForeignTitle].to_a,
      :links => xml[:Links].split("|"),
      :doi => xml[:DOI].split("|"),
      :abstract => xml[:Abstract].to_a,
      :notes => xml[:Notes].to_a,
      :folder => xml[:Folder].to_a,
      :user_1 => xml[:User1].to_a,
      :user_2 => xml[:User2].split(/\||;/).each{|k| k.strip!},
      :user_3 => xml[:User3].to_a,
      :user_4 => xml[:User4].to_a,
      :user_5 => xml[:User5].to_a,
      :call_number => xml[:CallNumber].to_a,
      :database_name => xml[:DatabaseName].to_a,
      :data_source => xml[:DataSource].to_a,
      :identifying_phrase => xml[:IdentifyingPhrase].to_a,
      :retrieved_date => xml[:RetrievedDate].to_a,
      :shortened_title => xml[:ShortenedTitle].to_a,
      :text_attributes => xml[:TextAttributes].to_a,
      :url => xml[:URL].split("|"),
      :sponsoring_library => xml[:SponsoringLibrary].to_a,
      :sponsoring_library_location => xml[:SponsoringLibraryLocation].to_a,
      :cited_refs => xml[:CitedRefs].to_a,
      :website_title => xml[:WebsiteTitle].to_a,
      :website_editor => xml[:WebsiteEditor].to_a,
      :website_version => xml[:WebsiteVersion].to_a,
      :pub_date_electronic => xml[:PubDateElectronic].to_a,
      :source_type => xml[:SourceType].to_a,
      :over_flow => xml[:OverFlow].to_a,
      :objects => xml[:Objects].to_a,
      :original_data => xml
    }
  end 
end