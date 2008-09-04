class ExternalSystemUri < ActiveRecord::Base
  
  #### Associations ####
  belongs_to :work
  belongs_to :external_system
  
  validates_presence_of :work_id, :external_system_id, :uri
end
