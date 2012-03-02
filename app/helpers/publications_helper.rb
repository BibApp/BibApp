module PublicationsHelper

  def work_count_hash(publications)
    with_ids_from(publications) do |ids|
      Work.joins(:contributorships).verified.where(:publication_id => ids).group(:publication_id).select("distinct(works.id)").count
    end
  end

  def publisher_data_hash(publications)
    with_ids_from(publications) do |ids|
      Publication.where(:id => ids).joins(:publisher).
          select('publications.id as id, publishers.id as publ_id, publishers.name as publ_name, publishers.romeo_color as publ_color').
          each_with_object({}) do |pub, hash|
        hash[pub.id] = {:id => pub.publ_id, :name => pub.publ_name, :color => pub.publ_color}
      end
    end
  end

end