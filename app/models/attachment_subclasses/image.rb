class Image < Attachment

  #Override Attachment settings for images
  validates_attachment_content_type :data, :content_type => /image/

end
