class AddSortName < ActiveRecord::Migration

  KLASSES = [Group, Publication, Publisher, Work]

  def self.up
    KLASSES.each do |klass|
      add_column klass.table_name, :sort_name, :string
      klass.reset_column_information
      #most of the time the sort_name will be the same as the machine_name, so doing this bulk update
      #first will save time, as update_all_sort_names will only do a save when sort_name actually changes
      klass.update_all('sort_name = machine_name')
      klass.update_all_sort_names
    end
  end

  def self.down
    KLASSES.each do |klass|
      remove_column klass.table_name, :sort_name
    end
  end

end
