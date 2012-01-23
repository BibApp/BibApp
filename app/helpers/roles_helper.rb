module RolesHelper

  def index_header(authorizable)
    if authorizable == System
      t('common.roles.index_header_system_html', :app_name => t('personalize.application_name'))
    elsif authorizable.kind_of?(Group)
      t('common.roles.index_header_group_html', :group => group_link(authorizable))
    elsif @authorizable.kind_of?(Person)
      t('common.roles.index_header_person_html', :person => person_link(authorizable))
    end
  end

  def form_header(authorizable, role_name)
    translated_role = t_bibapp_role_name(role_name)
    if authorizable.is_a? Class and authorizable == System
      t('common.roles.form_header_system_html', :role => translated_role, :app_name => t('personalize.application_name'))
    elsif authorizable.kind_of?(Group)
      t('common.roles.form_header_group_html', :role => translated_role, :group => group_link(authorizable))
    elsif @authorizable.kind_of?(Person)
      t('common.roles.form_header_person_html', :role => translated_role, :person => person_link(authorizable))
    end
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