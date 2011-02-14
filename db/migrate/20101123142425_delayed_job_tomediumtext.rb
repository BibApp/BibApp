class DelayedJobTomediumtext < ActiveRecord::Migration
  def self.up
    change_column :delayed_jobs, :handler, :text, :size => 16777215
  end

  def self.down
    change_column :delayed_jobs, :handler, :text
  end
end
