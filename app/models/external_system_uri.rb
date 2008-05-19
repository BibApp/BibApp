class ExternalSystemUri < ActiveRecord::Base
  
  #### Associations ####
  belongs_to :citation
  belongs_to :external_system
  
  validates_presence_of :citation_id, :external_system_id, :uri
end
