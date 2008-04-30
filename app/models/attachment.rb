class Attachment < ActiveRecord::Base
  #### Associations ####
  belongs_to :asset, :polymorphic => true # Polymorphism!
  
  
  #### Default Attachment_fu settings ####
  has_attachment :storage => :file_system, 
                 :size => 0.kilobyte...100.megabytes
  
  #validates_as_attachment
  #Custom validation messages
  validates_attachment :empty => "You forgot to select a file to upload, or the selected file had no contents.",
                       :size  => "The file you uploaded was larger than the maximum size of 100MB." 
  
  # List of all currently enabled Attachment types
  def self.types               
    types = [
      "Content File",  #Default type of attachment
      "Image"
    ]  
  end
  
  # Provide a filesize method to specify
  # actual size in terms of bytes, KB, MB or GB
  def filesize
    # if >= billion bytes, specify in GB
    if self.size >= 1000000000
      filesize=self.size.div(1000000000).round.to_s + "GB"
    # if >= million bytes, specify in MB
    elsif self.size >= 1000000
      filesize=self.size.div(1000000).round.to_s + "MB"
    # if >= thousand bytes, specify in KB
    elsif self.size >= 1000
      filesize=self.size.div(1000).round.to_s + "KB"
    # if < thousand bytes, specify in bytes
    elsif self.size < 1000
      filesize=self.size.to_s + "bytes"
    end
  end
  
  # Return the full URL of the file in BibApp
  # Needs the request object to build the URL
  def public_url(request)
    request.protocol+request.host_with_port+self.public_filename
  end 
end
