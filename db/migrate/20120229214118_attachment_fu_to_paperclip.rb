#This is heavily influenced if not an outright copy of https://gist.github.com/375203
module PaperclipMigrations

  def self.included(base)
    base.extend ClassMethods
  end

  module ClassMethods
    def populate_paperclip_from_attachment_fu(model, attachment, prefix, path_prefix)
      unless attachment.filename.nil?
        model.send("#{prefix}_file_name=", attachment.filename)
        model.send("#{prefix}_content_type=", attachment.content_type)
        model.send("#{prefix}_file_size=", attachment.size)
        puts "# data_file_name: #{model.send("#{prefix}_file_name")}"
        puts "# data_content_type: #{model.send("#{prefix}_content_type")}"
        puts "# data_file_size: #{model.send("#{prefix}_file_size")}"

        # Get file path from attachment_fu
        file_path = ("%08d" % model.id).scan(/..../).join('/')
        old_path = File.join(Rails.root, 'public', path_prefix, file_path, attachment.filename)
        new_path = model.send(prefix).path(:original)
        new_folder = File.dirname(new_path)

        if File.exists?(old_path)
          unless File.exists?(new_folder)
            FileUtils.mkdir_p(new_folder)
          end

          puts "Copying #{old_path} to #{new_path}"
          system("cp #{old_path} #{new_path}")
          model.save!
        else
          puts "No such file: #{old_path}"
        end
        puts "# -------- END #"
      end
    end
  end
end

class AttachmentFuToPaperclip < ActiveRecord::Migration

  include PaperclipMigrations

  def self.up
    # Paperclip
    add_column :attachments, :data_file_name, :string
    add_column :attachments, :data_content_type, :string
    add_column :attachments, :data_file_size, :integer
    add_column :attachments, :data_updated_at, :datetime

    # Update table information
    Attachment.reset_column_information

    # Delete all attachment_fu image sizes
    Attachment.delete_all("parent_id IS NOT NULL")
    remove_column :attachments, :parent_id

    # Migrate data
    Attachment.all.each do |attachment|
      populate_paperclip_from_attachment_fu(attachment, attachment, 'data', 'attachments') if attachment
      #attachment.reprocess! if attachment
    end

    # After data migration and paperclip reprocessing remove attachment_fu columns
    remove_column :attachments, :filename
    remove_column :attachments, :content_type
    remove_column :attachments, :size
  end

  def self.down
    raise ActiveRecord::IrreversibleMigration
  end
end
