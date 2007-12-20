class Membership < ActiveRecord::Base
  belongs_to :group
  belongs_to :person
  
  validates_presence_of :group_id, :person_id
  validates_uniqueness_of :person_id, :scope => :group_id
  
end
