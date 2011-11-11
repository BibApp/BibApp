class SplitPublicationDateInWorks < ActiveRecord::Migration
  def self.up
    add_column :works, :publication_date_year, :integer
    add_column :works, :publication_date_month, :integer
    add_column :works, :publication_date_day, :integer
    Work.all.each do |work|
      if work.publication_date.present?
        work.publication_date_year = work.publication_date.year
        work.publication_date_month = work.publication_date.month
        work.publication_date_day = work.publication_date.day
      else
        work.publication_date_year = nil
        work.publication_date_month = nil
        work.publication_date_day = nil
      end
      work.save
    end
    remove_column :works, :publication_date
  end

  def self.down
    add_column :works, :publication_date, :date
    Work.all.each do |work|
      if work.publication_date_year.present?
        work.publication_date = Date.new(work.publication_date_year, work.publication_date_month || 1, work.publication_date_day || 1)
      else
        work.publication_date = nil
      end
      work.save
    end
    remove_column :works, :publication_date_day
    remove_column :works, :publication_date_month
    remove_column :works, :publication_date_year
  end
end
