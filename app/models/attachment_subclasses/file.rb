class File < Attachment
  #Attachment_fu settings
  has_attachment :storage => :file_system, 
                 :max_size => 100.megabytes

  validates_as_attachment
end
