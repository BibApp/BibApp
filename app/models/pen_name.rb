class PenName < ActiveRecord::Base
  belongs_to :author_string
  belongs_to :person
  
  validates_presence_of :author_string_id, :person_id
  
end
