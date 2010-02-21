class UpdateImportErrorColumn < ActiveRecord::Migration
  def self.up
    rename_column(Import, :errors, :import_errors)
  end

  def self.down
    # Important column name change, don't go back.
    raise ActiveRecord::IrreversibleMigration, "Sorry, you can't migrate down."
  end
end
