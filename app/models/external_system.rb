require 'lib/machine_name'
class ExternalSystem < ActiveRecord::Base
  include MachineNameUpdater

  #### Associations ####
  has_many :works, :through => :external_system_uris
  
  validates_presence_of :name, :base_url
   
  #### Callbacks ####
  before_save :update_machine_name

end
