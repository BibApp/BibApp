# PenNames provide the logic for creating and destroying Contributorships
#   see the PenNameObserver for how these Contributorships are created/destroyed
class PenName < ActiveRecord::Base
  belongs_to :name_string
  belongs_to :person
  has_many :contributorships
  
  validates_presence_of :name_string_id, :person_id
 
end
