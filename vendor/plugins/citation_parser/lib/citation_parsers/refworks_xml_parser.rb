class RefworksXmlParser < CitationParser
  require 'hpricot'
    
  def parse(data)
    xml = Hpricot.XML(data)
    return nil if (xml/'z:row').nil?
  
    (xml/'z:row').each { |ref|
      puts "Ref: #{ref}\n\n"
      # add the citation to the database
      c = ParsedCitation.new(:refworks_xml)
      c.properties = param_hash(ref)
      @citations << c
    }

    @citations
  end
  
  def param_hash(xml)
    return {
      :reftype_id => xml[:RefType].to_a,
      :author_strings => xml[:AuthorPrimary].split("|"),
      :affiliations => xml[:AuthorSecondary].to_a,
      :title_primary => xml[:TitlePrimary].to_a,
      :title_secondary => xml[:TitleSecondary].to_a,
      :title_tertiary => xml[:TitleTertiary].to_a,
      :keywords => xml[:Keyword].split("|"),
      :year => xml[:PubYear].to_a,
      :periodical_full => xml[:PeriodicalFull].to_a,
      :periodical_abbrev => xml[:PeriodicalAbbrev].to_a,
      :volume => xml[:Volume].to_a,
      :issue => xml[:Issue].to_a,
      :start_page => xml[:StartPage].to_a,
      :end_page => xml[:OtherPages].to_a,
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
      :user_2 => xml[:User2].to_a,
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