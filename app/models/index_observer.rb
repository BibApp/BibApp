# Index Observer:
#   Performs all Solr re-indexing for BibApp using Index model
#   @TODO: pen_name_observer still has its own Indexing code that should be refactored
class IndexObserver < ActiveRecord::Observer
  require 'index.rb'

  # Observe all models related to indexed Work information
  observe Work, Person, Group, Publication, Publisher, Attachment, Membership

  def after_save(record)
    record.logger.debug("\n\n === AFTER-SAVE IN INDEX OBSERVER ===\n\n")

    if reindex?(record)
      #check if we are re-indexing one work, or multiple
      case record
        when Work #one work
          Index.update_solr(record)

        else #multiple works
          works = get_associated_works(record)

          works.each { |work| work.set_for_index_and_save }
          Index.delay.batch_index
      end
    end
  end

  def before_destroy(record)
    #check if we destroyed a Work, or another model
    case record
      when Work #destroyed a Work
        #completely remove work from Solr
        Index.remove_from_solr(record)

      else #destroyed a different model -> just want to re-indexed associate works
        works = get_associated_works(record)

        # Check to see if object has associated works -- attachments for archiving will not.
        if !works.nil?
          works.each { |work| work.set_for_index_and_save }
          Index.delay.batch_index
        end
    end
  end


  #Determine if re-indexing is necessary, based on changes made to model
  def reindex?(record)

    case record
      #Work: only update index if it has changed and it's not marked for batch indexing
      when Work
        return true if !record.batch_index? and record.changed?

      #Person: only update index if name or machine_name changed
      when Person
        return true if record.first_name_changed? or record.last_name_changed? or record.machine_name_changed? or record.active_changed? or record.research_focus_changed?

      #Group: only update index if name or machine_name changed
      when Group
        return true if record.name_changed? or record.machine_name_changed? or record.hide_changed?

      #Publication/Publisher: only update index if Authority, name or machine_name changed
      when Publication, Publisher
        return true if record.authority_id_changed? or record.name_changed? or record.machine_name_changed?

      #Attachment: only update index if attachment is a Person's image
      when Attachment
        return true if record.asset.kind_of?(Person) and record.kind_of?(Image)

      #Membership: only update index if there are changes
      when Membership
        return true if record.changed?

      else
        #default to not reindexing
        return false
    end
  end


  # Get works which require re-indexing, based on the model
  def get_associated_works(record)

    case record
      #Person: return all verified works
      when Person
        return record.works.verified

      #Group/Publication/Publisher: return all works
      when Group, Publication, Publisher
        return record.works

      #Attachment: return all verified works of Person asset (only if this is a Person's image)
      when Attachment
        return record.asset.works.verified if record.asset.kind_of?(Person) and record.kind_of?(Image)

      #Membership: return all verified works of Person
      when Membership
        return record.person.works.verified

      else
        # default to returning nothing
        return nil
    end
  end

end
