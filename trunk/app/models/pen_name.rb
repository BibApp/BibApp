class PenName < ActiveRecord::Base
  belongs_to :author
  belongs_to :person
  
  validates_presence_of :author_id, :person_id
end
