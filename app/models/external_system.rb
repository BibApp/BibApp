class ExternalSystem < ActiveRecord::Base
  
  #### Associations ####
  has_many :works, :through => :external_system_uris
  
  validates_presence_of :name, :base_url
   
  #### Callbacks ####
  after_save :update_machine_name
  
  #### Methods ####
  
  def save_without_callbacks
    update_without_callbacks
  end
  
  #Update Machine Name of ExternalSystem (called by after_save callback)
  def update_machine_name
    #Machine name only needs updating if there was a name change
    if self.name_changed?
      #Machine name is Group Name with:
      #  1. all punctuation/spaces converted to single space
      #  2. stripped of leading/trailing spaces and downcased
      self.machine_name = self.name.mb_chars.gsub(/[\W]+/, " ").strip.downcase
      self.save_without_callbacks
    end
  end
end
