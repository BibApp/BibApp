xml.instruct!
xml.red(:RDF, {'xmlns:rdf'=>"http://www.w3.org/1999/02/22-rdf-syntax-ns#", 'xmlns:bibo'=>"http://purl.org/ontology/bibo/", 'xmlns:foaf'=>"http://xmlns.com/foaf/0.1/", 'xmlns:owl'=>"http://www.w3.org/2002/07/owl#", 'xmlns:xsd'=>"http://www.w3.org/2001/XMLSchema#", 'xmlns:core'=>"http://vivoweb.org/ontology/core#", 'xmlns:vitro'=>"http://vitro.mannlib.cornell.edu/ns/vitro/0.7#", 'xmlns:rdfs'=>"http://www.w3.org/2000/01/rdf-schema#"}) do
  @works.each do |w|
    work = Work.find(w['pk_i'])
    (xml << render(:partial => "shared/package", :locals => {:work => work})) if work
  end
  if @has_next_page
    @page = @page == 0 ? 1 : @page
    xml.link({:rel => "next", :href => "#{works_url()}.rdf?page=#{@page.to_i+1}"})
  end
end