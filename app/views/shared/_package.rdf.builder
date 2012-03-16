locator = link_to_findit(work)
locator = locator.gsub(/<a\shref="/, "")
locator = locator.gsub(/">Find It<\/a>/, "")

peer_reviewed = ""
unless work.peer_reviewed.nil?
  peer_reviewed = work.peer_reviewed == true ? "true" : "false"
end

xml.rdf(:Description, 'rdf:about'=>"#{work_url(work)}") do
  xml.rdf(:type, 'rdf:resource'=>"http://purl.org/ontology/bibo/Document")
  if work.authors.present?
    xml.bibo(:authorList) do
      xml.rdf(:Seq) do
        work.authors.each do |a|
          xml.rdf(:li, a[:name])
        end
      end
    end
  end
  if work.editors.present?
    xml.bibo(:editorList) do
      xml.rdf(:Seq) do
        work.editors.each do |e|
          xml.rdf(:li, e[:name])
        end
      end
    end
  end
  xml.core(:title, h(work.title_primary))
  if work.abstract.present?
    xml.bibo(:abstract, h(work.abstract))
  end
  if work.publication_id.present?
    xml.core(:publishedInTitle, (work.publication.name))
    xml.core(:publishedIn, 'rdf:resource' => publication_url(work.publication))
  end
  if work.year.present?
    xml.core(:year, {'rdf:datatype'=>"http://www.w3.org/2001/XMLSchema#gYear"}, h(work.year))
  end
  if work.start_page.present?
    xml.bibo(:pageStart, {'rdf:datatype'=>"http://www.w3.org/2001/XMLSchema#int"}, work.start_page)
  end
  if work.end_page.present?
    xml.bibo(:pageEnd, {'rdf:datatype'=>"http://www.w3.org/2001/XMLSchema#int"}, h(work.end_page))
  end
  if peer_reviewed.present?
    xml.core(:refereedStatus, {'rdf:datatype'=>"http://www.w3.org/2001/XMLSchema#boolean"}, peer_reviewed)
  end
  if work.links.present?
    xml.bibo(:doi, {'rdf:datatype'=>"http://www.w3.org/2001/XMLSchema#string"}, h(work.links))
  end
  xml.core(:localLibraryLink, {'rdf:datatype'=>"http://www.w3.org/2001/XMLSchema#string"}, locator)
  xml.bibo(:coins, {'rdf:datatype'=>"http://www.w3.org/2001/XMLSchema#string"}, h(coin(work)))
  xml.vitro(:timekey, {'rdf:datatype'=>"http://www.w3.org/2001/XMLSchema#dateTime"}, work.created_at)
  xml.vitro(:modTime, {'rdf:datatype'=>"http://www.w3.org/2001/XMLSchema#dateTime"}, work.updated_at)
  if work.people.present?
    xml.core(:informationResourceInAuthorship, {'rdf:resource' => "#{work_url(work)}#Authorship"})
  end
end

xml.rdf(:Description, {'rdf:about'=>"#{work_url(work)}#Authorship"}) do
  xml.rdf(:type, {'rdf:resource'=>"http://vivoweb.org/ontology/core#Authorship"})
  xml.core(:linkedInformationResource, {'rdf:resource'=> work_url(work)})
  work.people.each do |p|
    xml.core(:linkedAuthor, {'rdf:resource'=> person_url(p)})
  end
end
