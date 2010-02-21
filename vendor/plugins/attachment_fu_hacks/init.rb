# Customization of attachment_fu plugin for BibApp
#
# This "evil twin" plugin does a few things:
#
# (1) Adds 'validates_attachment', which gives us more control 
#     over the validation error messages returned by attachment_fu.  
#     Code borrowed from:
#     http://toolmantim.com/article/2007/12/3/rollin_your_own_attachment_fu_messages_evil_twin_stylee
#
# (2) Fixes problems with running attachment_fu on Windows machines.  
#     By default, on Windows, attachment_fu *always* sets filesize 
#     to zero (even though it uploads successfully).  
#     Code borrowed from:
#     http://www.railsforum.com/viewtopic.php?id=6307
#
# For more info on "evil twin" plugins:
#    http://errtheblog.com/posts/67-evil-twin-plugin
#
Technoweenie::AttachmentFu::InstanceMethods.module_eval do
  
    # Fix uploaded_data= method for Windows
    # Attachment_fu on Windows doesn't get size of data properly (it's always set to zero)
    #   See:  http://www.railsforum.com/viewtopic.php?id=6307
    def uploaded_data=(file_data)
        return nil if file_data.nil? || file_data.size == 0
        self.size = file_data.size  # Added for Windows Fix
        self.content_type = file_data.content_type
        self.filename     = file_data.original_filename if respond_to?(:filename)
        if file_data.is_a?(StringIO)
          file_data.rewind
          self.temp_data = file_data.read
        else
          self.temp_path = file_data
        end
    end
    
  protected
    # Fix setting of file size for Windows
    # Attachment_fu on Windows doesn't get size of data properly (it's always set to zero)
    #   See:  http://www.railsforum.com/viewtopic.php?id=6307
    def set_size_from_temp_path
      # Fix for Windows...only set 'self.size' if not already set
      self.size = File.size(temp_path) if save_attachment? && (self.size == 0 || self.size.nil?)
    end
    
    # Custom Validation of Attachments, called by validate_attachment below
    #   See: http://toolmantim.com/article/2007/12/3/rollin_your_own_attachment_fu_messages_evil_twin_stylee
    def attachment_valid?
      if self.filename.nil?
        errors.add_to_base attachment_validation_options[:empty]
        return
      end
      [:content_type, :size].each do |option|
        if attachment_validation_options[option] && attachment_options[option] && !attachment_options[option].include?(self.send(option))
          errors.add_to_base attachment_validation_options[option]
        end
      end
    end
end

Technoweenie::AttachmentFu::ClassMethods.module_eval do
  # 'validates_attachment' method which allows you to specify custom error messages
  #   See: http://toolmantim.com/article/2007/12/3/rollin_your_own_attachment_fu_messages_evil_twin_stylee
  # Options: 
  # *  <tt>:empty</tt> - Base error message when no file is uploaded. Default is "No file uploaded" 
  # *  <tt>:content_type</tt> - Base error message when the uploaded file is not a valid content type.
  # *  <tt>:size</tt> - Base error message when the uploaded file is not a valid size.
  #
  # Example:
  #   validates_attachment :content_type => "The file you uploaded was not a JPEG, PNG or GIF",
  #                        :size         => "The image you uploaded was larger than the maximum size of 10MB" 
  def validates_attachment(options={})
    options[:empty] ||= "No file uploaded" 
    class_inheritable_accessor :attachment_validation_options
    self.attachment_validation_options = options
    validate :attachment_valid?
  end
end