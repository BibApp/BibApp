require 'solr_updater'
class Membership < ActiveRecord::Base
  include SolrUpdater
  belongs_to :person
  belongs_to :group

  #No duplicate memberships, please
  validates_uniqueness_of :person_id, :scope => :group_id

  html_fragment :title, :scrub => :escape

  acts_as_list  :scope => :person

  scope :active, where("end_date is ?", nil)

  def get_associated_works
    self.person.works.verified
  end

  def require_reindex?
    self.changed?
  end

end