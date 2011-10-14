module TranslationsHelper
  def t_bibapp_role_name(role_name, opts = {})
    opts.reverse_merge!(:count => 1)
    t("common.roles.#{role_name.downcase}", opts)
  end

  def t_work_role_name(role_name)
    t("work_roles.#{canonicalize_work_role_name(role_name)}")
  end

  #turns the english string for the role name into the appropriate string to do a translation lookup
  #TODO - now that we're handling all the display through the translations interface, it'd be better to
  #just make all of the keys in the work subclasses into symbols or the corresponding strings in the first place
  #Once I18n is in place I think this would require little more than changing them in the models and writing
  #a migration to update the database appropriately, based on this method.
  def canonicalize_work_role_name(role_name)
    role_name.gsub(/[ -]/, '_').downcase
  end

  def t_sherpa_color_explanation(color_string_or_sym)
    t("personalize.sherpa_colors.#{color_string_or_sym.to_s.downcase}")
  end

  def t_work_status(status_id)
    t('personalize.work_status')[status_id.to_i]
  end

end