module RolesHelper

  def index_header(authorizable)
    if authorizable == System
      t('common.roles.index_header_system', :app_name => $APPLICATION_NAME)
    elsif authorizable.kind_of?(Group)
      t('common.roles.index_header_group', group_link(authorizable)).html_safe
    elsif @authorizable.kind_of?(Person)
      t('common.roles.index_header_person', person_link(authorizable)).html_safe
    end
  end

  def form_header(authorizable, role_name)
    translated_role = t_role_name(role_name)
    if authorizable.is_a? Class and authorizable == System
      t('common.roles.form_header_system', :role => translated_role, :app_name => $APPLICATION_NAME)
    elsif authorizable.kind_of?(Group)
      t('common.roles.form_header_group', :role => translated_role, :group => group_link(authorizable))
    elsif @authorizable.kind_of?(Person)
      t('common.roles.form_header_person', :role => translated_role, :person => person_link(authorizable))
    end.html_safe
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

  def t_role_name(role_name, opts = {})
    opts.reverse_merge!(:count => 1)
    t("common.roles.#{role_name.downcase}", opts)
  end

end