# Index Observer:
#   Performs Solr re-indexing for BibApp using Index model
class IndexObserver < ActiveRecord::Observer

  # Observe all models related to indexed Work information
  observe Work, Person, Group, Publication, Publisher, Attachment, Membership

  def after_save(record)
    if record.try(:require_reindex?)
      record.reindex_after_save
    end
  end

  def before_destroy(record)
    record.try(:reindex_before_destroy)
  end

end
