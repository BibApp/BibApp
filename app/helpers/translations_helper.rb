module TranslationsHelper
  def t_bibapp_role_name(role_name, opts = {})
    opts.reverse_merge!(:count => 1)
    t("common.roles.#{role_name.downcase}", opts)
  end

  def t_work_role_name(role_name)
    t_work_role_name_with_count(role_name, 1)
  end

  def t_work_role_name_pl(role_name)
    t_work_role_name_with_count(role_name, 2)
  end

  def t_work_role_name_with_count(role_name, count)
    t("work_roles.#{canonicalize_work_role_name(role_name)}", :count => count)
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
    t("personalize.sherpa_colors.#{color_string_or_sym.to_s.downcase}.explanation")
  end

  def t_work_status(status_id)
    t('personalize.work_status')[status_id.to_i]
  end

  def t_solr_work_type(type)
    type.titlecase.gsub(' ', '').constantize.model_name.human
  end

  def t_solr_work_type_pl(type)
    type.titlecase.gsub(' ', '').constantize.model_name.human_pl
  end

  #For i18n - since 'Unknown' is stored as a name in the db for unknown publications/publishers
  #we need to translate if this is the value. This is kind of kludgy, but will have to do for now
  def name_or_unknown(name)
    if is_unknown?(name)
      translate_unknown(name)
    else
      name
    end
  end

  #return array of arrays. Each sub-array is a pair - the first is the type and the second is the label for the current
  #locale. Sorted by the labels.
  def sorted_work_types
    Work.types.collect {|type| [type, type.gsub(/[()\/ ]/, '').constantize.model_name.human]}.sort_alphabetical_by {|a| a.last}
  end

  protected

  #Need to handle the cases where the name is just 'Unknown' or if it has some identifiers appended to it
  def is_unknown?(name)
    return '' if name.match(/^\s*Unknown\s*$/)
    name.match(/Unknown(\s*\(.*\))?/)
    return $1
  end

  def translate_unknown(name)
    name.sub(/Unknown/, t('app.unknown'))
  end

end