# METS Metadata Wrapper, which contains metadata
# in EPrints DC XML Schema (epdcx) - As necessary for SWORD
# See: http://www.ukoln.ac.uk/repositories/digirep/index/Eprints_Application_Profile
xml.mdWrap(:LABEL => "SWORD Metadata - EPrints DC XML schema", :MDTYPE => "OTHER", :OTHERMDTYPE => "EPDCX", :MIMETYPE => "text/xml") do
  xml.xmlData do
    xml.epdcx(:descriptionSet, 'epdcx:resourceId' => "sword-mets-epdcx-#{work.id}") do
      xml.epdcx(:description, 'epdcx:resourceId' => "sword-mets-epdcx-#{work.id}") do
        xml.epdcx(:statement, 'epdcx:propertyURI' => "http://purl.org/dc/elements/1.1/type", 'epdcx:valueURI' => "http://purl.org/eprint/entityType/ScholarlyWork")
        xml.epdcx(:statement, 'epdcx:propertyURI' => "http://purl.org/dc/elements/1.1/title") do
          xml.epdcx(:valueString, work.title_primary.to_xs)
        end
        work.tags.each do |tag|
          xml.epdcx(:statement, 'epdcx:propertyURI' => "http://purl.org/dc/elements/1.1/subject") do
            xml.epdcx(:valueString, tag.name.to_xs)
          end
        end
        if work.abstract.present? and $EXPORT_ABSTRACTS_AND_KEYWORDS
          xml.epdcx(:statement, 'epdcx:propertyURI' => "http://purl.org/dc/terms/abstract") do
            xml.epdcx(:valueString, work.abstract.to_xs)
          end
        end
        work.work_name_strings.where(:role => work.creator_role).includes(:name_string).each do |wns|
          xml.epdcx(:statement, 'epdcx:propertyURI' => "http://purl.org/dc/elements/1.1/creator") do
            xml.epdcx(:valueString, wns.name_string.name.to_xs)
          end
        end
        xml.epdcx(:statement, 'epdcx:propertyURI' => "http://purl.org/eprint/terms/isExpressedAs", 'epdcx:valueRef' => "sword-mets-expr-#{work.id}")
      end
      xml.epdcx(:description, 'epdcx:resourceId' => "sword-mets-expr-#{work.id}") do
        xml.epdcx(:statement, 'epdcx:propertyURI' => "http://purl.org/dc/elements/1.1/type", 'epdcx:valueURI' => "http://purl.org/eprint/entityType/Expression")
        if work.title_secondary.present?
          xml.epdcx(:statement, 'epdcx:propertyURI' => "http://purl.org/dc/elements/1.1/title") do
            xml.epdcx(:valueString, work.title_secondary.to_xs)
          end
        end
        if work.title_tertiary.present?
          xml.epdcx(:statement, 'epdcx:propertyURI' => "http://purl.org/dc/elements/1.1/title") do
            xml.epdcx(:valueString, work.title_tertiary.to_xs)
          end
        end
        if work.notes.present?
          xml.epdcx(:statement, 'epdcx:propertyURI' => "http://purl.org/dc/elements/1.1/description") do
            xml.epdcx(:value_string, work.notes.to_xs)
          end
        end
        if work.publication_date_year
          xml.epdcx(:statement, 'epdcx:propertyURI' => "http://purl.org/dc/terms/available") do
            xml.epdcx(:valueString, {'epdcx:sesURI' => "http://purl.org/dc/terms/W3CDTF"}, work.publication_date_year)
          end
        end
        if work.language
          xml.epdcx(:statement, 'epdcx:propertyURI' => "http://purl.org/dc/elements/1.1/language", 'epdcx:vesURI' => "http://purl.org/dc/terms/RFC3066") do
            xml.epdcx(:valueString, work.language.to_xs)
          end
        end
        if work.type_uri.present?
          if work.type_uri.include?('eprint/type')
            xml.epdcx(:statement, 'epdcx:propertyURI' => "http://purl.org/dc/elements/1.1/type", 'epdcx:vesURI' => "http://purl.org/eprint/terms/Type", 'epdcx:valueURI' => "#{work.type_uri}")
          else
            xml.epdcx(:statement, 'epdcx:propertyURI' => "http://purl.org/dc/elements/1.1/type", 'epdcx:vesURI' => "http://purl.org/dc/dcmitype/", 'epdcx:valueURI' => "#{work.type_uri}")
          end
        end
        if work.copyright_holder
          xml.epdcx(:statement, 'epdcx:propertyURI' => "http://purl.org/eprint/terms/copyrightHolder") do
            xml.epdcx(:valueString, work.copyright_holder.to_xs)
          end
        end
        work.work_name_strings.where(:role => work.contributor_role).includes(:name_string).each do |wns|
          xml.epdcx(:statement, 'epdcx:propertyURI' => "http://www.loc.gov/loc.terms/relators/EDT") do
            xml.epdcx(:valueString, wns.name_string.name.to_xs)
          end
        end
        xml.epdcx(:statement, 'epdcx:propertyURI' => "http://purl.org/dc/terms/bibliographicCitation") do
          xml.epdcx(:valueString, work.to_s.to_xs)
          xml << (render(:partial => 'works/epdcx_openurl.mets', :locals => {:work => work}))
        end
        work.attachments.each do |att|
          xml.epdcx(:statement, 'epdcx:propertyURI' => "http://purl.org/eprint/terms/isManifestedAs", 'epdcx:valueRef' => "sword-mets-manifest-#{att.id}")
        end
      end
      work.attachments.each do |att|
        filepath = filenames_only ? att.filename : att.public_url(request)
        xml.epdcx(:description, 'epdcx:resourceId' => "sword-mets-manifest-#{att.id}") do
          xml.epdcx(:statement, 'epdcx:propertyURI' => "http://purl.org/dc/elements/1.1/type", 'epdcx:valueURI' => "http://purl.org/eprint/entityType/Manifestation")
          xml.epdcx(:statement, 'epdcx:propertyURI' => "http://purl.org/dc/elements/1.1/format", 'epdcx:valueURI' => "http://purl.org/dc/terms/IMT") do
            xml.epdcx(:valueString, att.content_type.to_xs)
          end
          if work.publisher
            xml.epdcx(:statement, 'epdcx:propertyURI' => "http://purl.org/dc/elements/1.1/publisher") do
              xml.epdcx(:valueString, work.publisher.authority.name.to_xs)
            end
          end
          xml.epdcx(:statement, 'epdcx:propertyURI' => "http://purl.org/eprint/terms/isAvailableAs", 'epdcx:valueURI' => filepath)
        end
        xml.epdcx(:description, 'epdcx:resourceURI' => filepath) do
          xml.epdcx(:statement, 'epdcx:propertyURI' => "http://purl.org/dc/elements/1.1/type", 'epdcx:valueURI' => "http://purl.org/eprint/entityType/Copy")
        end
      end
    end
  end
end