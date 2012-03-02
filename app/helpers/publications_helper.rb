module PublicationsHelper

  def work_count_hash(publications)
    with_ids_from(publications) do |ids|
      Work.joins(:contributorships).verified.where(:publication_id => ids).group(:publication_id).select("distinct(works.id)").count
    end
  end
end
