class ExternalSystem < ActiveRecord::Base
  
   #### Associations ####
   has_many :works, :through => :external_system_uris
  
   validates_presence_of :name, :base_url
end
