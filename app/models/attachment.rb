class Attachment < ActiveRecord::Base
  #### Associations ####
  belongs_to :asset, :polymorphic => true # Polymorphism!
  
  
  # List of all currently enabled Attachment Types
  def self.types               
    types = [
      "File",
      "Image"
    ]  
  end
 
end
