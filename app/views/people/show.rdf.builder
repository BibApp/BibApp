xml.instruct!
xml.rdf(:RDF, {'xmlns:rdf'=>"http://www.w3.org/1999/02/22-rdf-syntax-ns#", 'xmlns:bibo'=>"http://purl.org/ontology/bibo/", 'xmlns:foaf'=>"http://xmlns.com/foaf/0.1/", 'xmlns:owl'=>"http://www.w3.org/2002/07/owl#", 'xmlns:xsd'=>"http://www.w3.org/2001/XMLSchema#", 'xmlns:core'=>"http://vivoweb.org/ontology/core#", 'xmlns:vitro'=>"http://vitro.mannlib.cornell.edu/ns/vitro/0.7#", 'xmlns:rdfs'=>"http://www.w3.org/2000/01/rdf-schema#"}) do
  (xml << render(:partial => "package", :locals => {:person => @person})) if @person
end