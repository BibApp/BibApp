require 'solr_updater'
class Attachment < ActiveRecord::Base
  include SolrUpdater
  #### Associations ####
  belongs_to :asset, :polymorphic => true # Polymorphism!

  #If we later want to revert to the default paperclip 3 style, change :id to :id_partition and move
  #the assets from abcdefghi to abc/def/ghi under data.
  has_attached_file :data, :url => '/system/data/:id/:style/:basename.:extension'
  validates_attachment_size :data, :in => 1.byte...100.megabytes
  validates_attachment_presence :data

  # List of all currently enabled Attachment types
  def self.types
    ["Content File", #Default type of attachment
     "Image",
     "Import File"]
  end
  
  def content_type
    self.data_content_type
  end

  # Provide a filesize method to specify
  # actual size in terms of bytes, KB, MB or GB
  def filesize
    # if >= billion bytes, specify in GB
    if self.data_file_size >= 1000000000
      self.data_file_size.div(1000000000).round.to_s + "GB"
      # if >= million bytes, specify in MB
    elsif self.data_file_size >= 1000000
      self.data_file_size.div(1000000).round.to_s + "MB"
      # if >= thousand bytes, specify in KB
    elsif self.data_file_size >= 1000
      self.data_file_size.div(1000).round.to_s + "KB"
      # if < thousand bytes, specify in bytes
    elsif self.data_file_size < 1000
      self.data_file_size.to_s + "bytes"
    end
  end

  # Return the full URL of the file in BibApp
  # Needs the request object to build the URL
  def public_url(request)
    request.protocol + request.host_with_port + self.url
  end

  def url
    self.data.url
  end

  def public_filename
    self.data.url
  end

  # Return the full path of the file on the local filesystem
  def absolute_path
    self.data.path
  end

  def filename
    self.data_file_name
  end

  def get_associated_works
    if self.asset.kind_of?(Person) and self.kind_of?(Image)
      self.asset.works.verified
    else
      return []
    end
  end

  def require_reindex?
    self.asset.kind_of?(Person) and self.kind_of?(Image)
  end

end
