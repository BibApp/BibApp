rss_document_on(xml) do
  xml.channel do
    xml.title t('personalize.university_short_name') + ": " + object.name
    xml.link link_url
    xml.description h(t('pub_common.show.description', :university_name => t('personalize.university_short_name'), :object_name => object.name))
    @works.each do |work|
      xml << render('shared/rss_item', :work => work, :author_name => object.name)
    end
  end
end