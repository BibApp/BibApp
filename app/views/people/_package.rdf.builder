xml.rdf(:Description, {'rdf:about'=>person_url(person)}) do
  xml.rdf(:type, {'rdf:resource'=>"http://xmlns.com/foaf/0.1/Person"})
  xml.core(:hasUNI, {'rdf:datatype'=>"http://www.w3.org/2001/XMLSchema#string"}, person.uid)
  xml.foaf(:lastName, {'rdf:datatype'=>"http://www.w3.org/2001/XMLSchema#string"}, person.last_name)
  xml.foaf(:firstName, {'rdf:datatype'=>"http://www.w3.org/2001/XMLSchema#string"}, person.first_name)
  if person.middle_name.present?
    xml.core(:middleName, {'rdf:datatype'=>"http://www.w3.org/2001/XMLSchema#string"}, person.middle_name)
  end
  if person.research_focus.present?
    xml.core(:researchFocus, {'rdf:datatype'=>"http://www.w3.org/2001/XMLSchema#string"}, h(person.research_focus))
  end
  if person.email.present?
    xml.core(:workEmail, {'rdf:datatype'=>"http://www.w3.org/2001/XMLSchema#string"}, person.email)
  end
  if person.phone.present?
    xml.core(:workPhone, {'rdf:datatype'=>"http://www.w3.org/2001/XMLSchema#string"}, person.phone)
  end
  person.works.each do |w|
    xml.core(:authorInAuthorship, {'rdf:resource'=>"#{work_url(w)}#Authorship"})
  end
end