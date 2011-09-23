module RolesHelper

  def index_header(authorizable)
    if authorizable == System
      "System-wide Roles: #{$APPLICATION_NAME}"
    elsif authorizable.kind_of?(Group)
      "Roles for Group: #{group_link(authorizable)}".html_safe
    elsif @authorizable.kind_of?(Person)
      "Roles for Person: #{person_link(authorizable)}".html_safe
    end
  end

  def form_header(authorizable, role_name)
    if authorizable.is_a? Class and authorizable==System
      "Add System-wide #{role_name}: #{$APPLICATION_NAME}"
    elsif authorizable.kind_of?(Group)
      "Add #{role_name} on Group: #{group_link(authorizable)}".html_safe
    elsif @authorizable.kind_of?(Person)
      "Add #{role_name} on Person: #{person_link(authorizable)}".html_safe
    end
  end

  def authorizable_type(authorizable)
    authorizable.is_a?(Class) ? authorizable.to_s : authorizable.class.to_s
  end

  def authorizable_id(authorizable)
    authorizable.is_a?(Class) ? nil : authorizable.id
  end

  def group_link(group)
    link_to h(group.name), group_path(group)
  end

  def person_link(person)
    link_to h(person.name), person_path(person)
  end

  def url_opts(user, role_name, authorizable)
    {:name => role_name, :user_id => user.id, :authorizable_type => authorizable_type(authorizable),
     :authorizable_id => authorizable_id(authorizable)}
  end

end