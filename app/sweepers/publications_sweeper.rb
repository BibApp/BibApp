class PublicationsSweeper < AbstractSweeper
  observe Work, Publisher, Publication, Contributorship

  def after_save(record)
    expire_content(record)
  end

  def after_update(record)
    expire_content(record)
  end

  def after_destroy(record)
    expire_content(record)
  end

  protected

  #normal expiration - expire based on publication ids. The publishers may be supplied or looked up from the ids
  #(note the option - this is used when a publication is destroyed and hence can't be looked up)
  def expire_ids_and_publications(ids, publications = nil)
    return if ids.blank?
    ids.each { |id| expire_row(id) }
    publications ||= Publication.find(ids)
    publications.collect { |p| p.sort_name.first.upcase }.compact.uniq.each { |page| expire_page(page) }
  end

  def expire_content(record)
    case record
      when Work
        expire_ids_and_publications(expired_ids(record, :publication_id_changed?) { [record.publication_id, record.publication_id_was].compact })
      when Publication
        expire_for_publication(record)
      when Publisher
        expire_ids_and_publications(expired_ids(record, :name_changed?, :romeo_color_changed?) { record.publication_ids })
      when Contributorship
        expire_ids_and_publications(expired_ids(record, :contributorship_state_id_changed?) { record.work.publication_id })
    end
  end

  #publications require a little special handling
  def expire_for_publication(record)
    ids = expired_ids(record, :name_changed?, :issn_isbn_changed?) { record.id }
    publications = record.destroyed? ? [record] : Publication.find(ids)
    expire_ids_and_publications(ids, publications)
    #if the beginning letter of the name changed then we need to expire the page corresponding to the old letter as well
    if need_to_expire_previous_page?(record)
      expire_page(record.sort_name_was.first)
    end
  end

  def expire_page(letter)
    bibapp_expire_fragment_all_locales(:controller => 'publications', :action => 'index', :page => letter.upcase, :action_suffix => 'index-table')
  end

  def expire_row(id)
    bibapp_expire_fragment_all_locales(:controller => 'publications', :action => 'index', :id => id, :action_suffix => 'publication-row')
  end

  def need_to_expire_previous_page?(publication)
    publication.name_changed? and publication.sort_name_was.present? and
        publication.sort_name.present? and publication.sort_name.first.upcase != publication.sort_name_was.first.upcase
  end
end