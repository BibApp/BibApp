class Feed < ActiveRecord::Base
  def self.from_bloglines_xml(person, xml)
    i = Feed.new
    i.person_id   = person.id
    i.title       = xml.elements["title"].text
    i.link        = xml.elements["link"].text
    i.description = xml.elements["description"].text
    i.pubDate     = xml.elements["pubDate"].text
    i.save
  end
end
