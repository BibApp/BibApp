module PenNamesHelper
  def body_header(person)
    "#{link_to(h(person.display_name), person_path(person))}: Pen Names".html_safe
  end

end
