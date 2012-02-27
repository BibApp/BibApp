class AddSortName < ActiveRecord::Migration

  KLASSES = [Group, Publication, Publisher, Work]

  def self.up
    KLASSES.each do |klass|
      add_column klass.table_name, :sort_name, :string
      klass.reset_column_information
      klass.update_all_sort_names
    end
  end

  def self.down
    KLASSES.each do |klass|
      remove_column klass.table_name, :sort_name
    end
  end

end
