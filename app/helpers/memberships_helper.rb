module MembershipsHelper

  def membership_person_link(person)
    link_to(h(person.display_name), person_path(person))
  end

end
