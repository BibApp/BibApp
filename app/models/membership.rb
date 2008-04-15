class Membership < ActiveRecord::Base
  belongs_to :person
  belongs_to :group
  
  acts_as_list  :scope => :person

  after_save do |membership|
    # Update Solr!
    # * Citations have many People...
    membership.person.contributorships.each do |c|
      Index.update_solr(c.citation)
    end
  end
end