class Authorship   < ActiveRecord::Base
  belongs_to :person
  belongs_to :citation
  belongs_to :pen_name
  
  validates_presence_of :person_id, :citation_id, :pen_name_id
  validates_uniqueness_of :citation_id, :scope => :person_id
end
