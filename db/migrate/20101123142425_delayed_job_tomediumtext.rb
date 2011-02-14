class DelayedJobTomediumtext < ActiveRecord::Migration
  def self.up
    if adapter_name.downcase == 'mysql'
      change_column :delayed_jobs, :handler, :mediumtext
    end
  end

  def self.down
    if adapter_name.downcase == 'mysql'
      change_column :delayed_jobs, :handler, :text
    end
  end
end
