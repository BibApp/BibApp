class Image < Attachment
  
  #Attachment_fu settings
  has_attachment :content_type => :image,
                 :storage => :file_system, 
                 :max_size => 1.megabytes
                 #:thumbnails => { :thumb => '100x100>' }

  #For image resizing or thumbnail creation, you will have to do some modifications
  #to this image model and its controllers/views.  For more info on dealing with
  #image resizing or thumbnails, see this great attachment_fu tutorial:
  #   http://clarkware.com/cgi/blosxom/2007/02/24#FileUploadFu

  validates_as_attachment
end
