require 'solr_updater'
class Attachment < ActiveRecord::Base
  include SolrUpdater
  #### Associations ####
  belongs_to :asset, :polymorphic => true # Polymorphism!

  has_attached_file :data
  validates_attachment_size :data, :in => 1.byte...100.megabytes
  validates_attachment_presence :data

  # List of all currently enabled Attachment types
  def self.types
    ["Content File", #Default type of attachment
     "Image",
     "Import File"]
  end

  # Provide a filesize method to specify
  # actual size in terms of bytes, KB, MB or GB
  def filesize
    # if >= billion bytes, specify in GB
    if self.size >= 1000000000
      self.size.div(1000000000).round.to_s + "GB"
      # if >= million bytes, specify in MB
    elsif self.size >= 1000000
      self.size.div(1000000).round.to_s + "MB"
      # if >= thousand bytes, specify in KB
    elsif self.size >= 1000
      self.size.div(1000).round.to_s + "KB"
      # if < thousand bytes, specify in bytes
    elsif self.size < 1000
      self.size.to_s + "bytes"
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

  def filesize
    self.data_file_size
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
