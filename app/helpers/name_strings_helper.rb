module NameStringsHelper
  def person_image(person)
    image_tag(person.image_url, :class => 'person-photo', :size => "75x100",
              :alt => person.display_name, :title => person.display_name)
  end
end
