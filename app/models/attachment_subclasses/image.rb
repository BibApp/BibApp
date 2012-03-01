class Image < Attachment

  #Override Attachment settings for images
  has_attached_file :data
  validates_attachment_content_type :data, :content_type => /image/

end
