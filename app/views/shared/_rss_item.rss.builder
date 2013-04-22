#require work and author name to be passed
xml.item do
  xml.title work['title']

  xml.description {
    xml.cdata!(work['type'])
    xml.cdata!(render(subclass_partial_for(work) + ".html.haml", :work => work))
    xml.cdata!(work['abstract'])
  }

  xml.link work_url(:only_path => false, :id => work['id'].split("-")[1])

  xml.guid work_url(:only_path => false, :id => work['id'].split("-")[1])

  xml.author h(author_name)
end