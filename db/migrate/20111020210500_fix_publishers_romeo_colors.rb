class FixPublishersRomeoColors < ActiveRecord::Migration
  def self.up
    Publisher.all.each do |p|
      if p.romeo_color.blank?
        p.romeo_color = 'unknown'
        p.save
      end
    end
  end

  def self.down
  end
end
