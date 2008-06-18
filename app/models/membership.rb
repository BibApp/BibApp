class Membership < ActiveRecord::Base
  belongs_to :person
  belongs_to :group
  
  acts_as_list  :scope => :person

  after_create do |membership|
    # Update Solr!
    # * Citations have many People...
    membership.person.contributorships.each do |c|
      if c.contributorship_state_id == 2
        c.citation.save_and_set_for_index_without_callbacks
      end
    end
    
    Index.batch_index
  end
  
  
  after_destroy do |membership|
    # Update Solr!
    # * Citations have many People...
    membership.person.contributorships.each do |c|
      if c.contributorship_state_id == 2
        c.citation.save_and_set_for_index_without_callbacks
      end
    end
    
    Index.batch_index
  end
  
end