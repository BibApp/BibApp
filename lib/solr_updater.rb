#This defines a methods that all things updated via the IndexObserver except for works will use.
#Work will define its own version
module SolrUpdater

  def reindex_after_save
    reindex_associated_works
  end

  def reindex_before_destroy
    reindex_associated_works
  end

  private

  def reindex_associated_works
    self.get_associated_works.each do |work|
      work.set_for_index_and_save
    end
    Index.delay.batch_index
  end

end