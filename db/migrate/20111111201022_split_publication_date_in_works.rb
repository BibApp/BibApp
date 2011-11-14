class SplitPublicationDateInWorks < ActiveRecord::Migration
  def self.up
    add_column :works, :publication_date_year, :integer
    add_column :works, :publication_date_month, :integer
    add_column :works, :publication_date_day, :integer
    IndexObserver.skip = true
    if ActiveRecord::Base.connection.adapter_name == 'PostgreSQL'
      sql = <<-SQL
        UPDATE WORKS
        SET publication_date_year = date_part('year', publication_date),
            publication_date_month = date_part('month', publication_date),
            publication_date_day = date_part('day', publication_date)
        WHERE publication_date IS NOT NULL
      SQL
      ActiveRecord::Base.connection.update_sql(sql)
    else
      Work.all.each do |work|
        if work.publication_date.present?
          work.update_attribute(:publication_date_year, work.publication_date.year)
          work.update_attribute(:publication_date_month, work.publication_date.month)
          work.update_attribute(:publication_date_day, work.publication_date.day)
        else
          work.update_attribute(:publication_date_year, nil)
          work.update_attribute(:publication_date_month, nil)
          work.update_attribute(:publication_date_day, nil)
        end
      end
    end
    remove_column :works, :publication_date
  end

  def self.down
    add_column :works, :publication_date, :date
    IndexObserver.skip = true
    if ActiveRecord::Base.connection.adapter_name == 'PostgreSQL'
      sql = <<-SQL
        UPDATE WORKS
        SET publication_date = date('0001-01-01') + ((publication_date_year - 1) * interval '1 year') +
          (coalesce (publication_date_month - 1, 1) * interval '1 month') +
          (coalesce (publication_date_day - 1, 1) * interval '1 day')
        WHERE publication_date_year IS NOT NULL
      SQL
      ActiveRecord::Base.connection.update_sql(sql)
    else
      Work.all.each do |work|
        if work.publication_date_year.present?
          work.update_attribute(:publication_date, Date.new(work.publication_date_year, work.publication_date_month || 1, work.publication_date_day || 1))
        else
          work.update_attribute(:publication_date, nil)
        end
      end
    end
    remove_column :works, :publication_date_day
    remove_column :works, :publication_date_month
    remove_column :works, :publication_date_year
  end
end
