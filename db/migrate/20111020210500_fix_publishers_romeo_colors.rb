class FixPublishersRomeoColors < ActiveRecord::Migration
  def self.up
    Publisher.all.each do |p|
      if p.romeo_color.blank?
        p.update_column(:romeo_color, 'unknown')
      end
    end
  end

  def self.down
  end
end
