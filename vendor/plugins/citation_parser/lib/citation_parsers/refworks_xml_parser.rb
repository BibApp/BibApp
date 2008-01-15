class RefworksXmlParser < CitationParser
  require 'rexml/document'
  
  def parse(data)
    begin 
      xml = REXML::Document.new(data)
    rescue
      return nil
    end
    
    return nil if xml.elements["//z:row"].nil?
  
    xml.elements.each("//z:row") { |ref|
      # add the citation to the database
      c = ParsedCitation.new(:refworks_xml)
      c.properties = param_hash(ref)
      @citations << c
    }

    @citations
  end
  
  def param_hash(xml)
    return {
      :reftype_id => xml.attributes["RefType"].to_a,
      :authors => xml.attributes["AuthorPrimary"].split("|"),
      :affiliations => xml.attributes["AuthorSecondary"].to_a,
      :title_primary => xml.attributes["TitlePrimary"].to_a,
      :title_secondary => xml.attributes["TitleSecondary"].to_a,
      :title_tertiary => xml.attributes["TitleTertiary"].to_a,
      :keywords => xml.attributes["Keyword"].split("|"),
      :year => xml.attributes["PubYear"].to_a,
      :periodical_full => xml.attributes["PeriodicalFull"].to_a,
      :periodical_abbrev => xml.attributes["PeriodicalAbbrev"].to_a,
      :volume => xml.attributes["Volume"].to_a,
      :issue => xml.attributes["Issue"].to_a,
      :start_page => xml.attributes["StartPage"].to_a,
      :end_page => xml.attributes["OtherPages"].to_a,
      :edition =>  xml.attributes["Edition"].to_a,
      :publisher => xml.attributes["Publisher"].to_a,
      :place_of_publication => xml.attributes["PlaceOfPublication"].to_a,
      :issn_isbn => xml.attributes["ISSN_ISBN"].to_a,
      :availability => xml.attributes["Availability"].to_a,
      :author_address_affiliations => xml.attributes["Author_Address_Affiliation"].to_a,
      :accession_number => xml.attributes["AccessionNumber"].to_a,
      :language => xml.attributes["Language"].to_a,
      :classification => xml.attributes["Classification"].to_a,
      :subfile_database => xml.attributes["SubFile_Database"].to_a,
      :original_foreign_title => xml.attributes["OriginalForeignTitle"].to_a,
      :links => xml.attributes["Links"].split("|"),
      :doi => xml.attributes["DOI"].split("|"),
      :abstract => xml.attributes["Abstract"].to_a,
      :notes => xml.attributes["Notes"].to_a,
      :folder => xml.attributes["Folder"].to_a,
      :user_1 => xml.attributes["User1"].to_a,
      :user_2 => xml.attributes["User2"].to_a,
      :user_3 => xml.attributes["User3"].to_a,
      :user_4 => xml.attributes["User4"].to_a,
      :user_5 => xml.attributes["User5"].to_a,
      :call_number => xml.attributes["CallNumber"].to_a,
      :database_name => xml.attributes["DatabaseName"].to_a,
      :data_source => xml.attributes["DataSource"].to_a,
      :identifying_phrase => xml.attributes["IdentifyingPhrase"].to_a,
      :retrieved_date => xml.attributes["RetrievedDate"].to_a,
      :shortened_title => xml.attributes["ShortenedTitle"].to_a,
      :text_attributes => xml.attributes["TextAttributes"].to_a,
      :url => xml.attributes["URL"].split("|"),
      :sponsoring_library => xml.attributes["SponsoringLibrary"].to_a,
      :sponsoring_library_location => xml.attributes["SponsoringLibraryLocation"].to_a,
      :cited_refs => xml.attributes["CitedRefs"].to_a,
      :website_title => xml.attributes["WebsiteTitle"].to_a,
      :website_editor => xml.attributes["WebsiteEditor"].to_a,
      :website_version => xml.attributes["WebsiteVersion"].to_a,
      :pub_date_electronic => xml.attributes["PubDateElectronic"].to_a,
      :source_type => xml.attributes["SourceType"].to_a,
      :over_flow => xml.attributes["OverFlow"].to_a,
      :objects => xml.attributes["Objects"].to_a,
      :original_data => xml
    }
  end 
end