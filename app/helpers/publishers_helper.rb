module PublishersHelper
  def sherpa_colors
    I18n.t('personalize.sherpa_colors').keys.collect { |k| k.to_s }.sort
  end

  def most_recent_year_hash(publishers)
    with_ids_from(publishers) do |ids|
      Work.where(:publisher_id => ids).group(:publisher_id).maximum(:publication_date_year)
    end
  end

  def publication_count_hash(publishers)
    with_ids_from(publishers) do |ids|
      Publication.where(:publisher_id => ids).group(:publisher_id).count
    end
  end
end
