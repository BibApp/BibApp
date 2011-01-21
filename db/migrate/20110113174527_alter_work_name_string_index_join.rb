class AlterWorkNameStringIndexJoin < ActiveRecord::Migration
  def self.up
    remove_index(:work_name_strings, :name => 'work_name_string_join')
    add_index(:work_name_strings, [:work_id, :name_string_id, :role],
        :name => 'work_name_string_role_join', :unique => true)
  end

  def self.down
    remove_index(:work_name_strings, :name => 'work_name_string_role_join')
    add_index(:work_name_strings, [:work_id, :name_string_id],
        :name => "work_name_string_join", :unique => true)
  end
end
