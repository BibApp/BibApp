class IncreaseSizeOfAuthorAffiliation < ActiveRecord::Migration
  def self.up
    change_column :citations, :affiliation, :text
  end

  def self.down
    # Do Not Return!
    raise ActiveRecord::IrreversibleMigration
  end
end
