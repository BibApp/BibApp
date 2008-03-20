class File < ActiveRecord::Base
  #Attachment_fu settings
  has_attachment :storage => :file_system, 
                 :max_size => 100.megabytes,
                 :path_prefix => 'public/uploads'

  #### Associations ####
  belongs_to :citation

  validates_as_attachment
end
