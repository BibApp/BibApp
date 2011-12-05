#This defines a methods that all things updated via the IndexObserver except for works will use.
#Work will define its own version
module SolrUpdater

  def reindex_after_save
    self.delay.reindex_associated_works
  end

  def reindex_before_destroy
    self.delay.reindex_associated_works
  end

  private

  def reindex_associated_works
    self.get_associated_works.each do |work|
      Index.update_solr(work)
    end
  end

end