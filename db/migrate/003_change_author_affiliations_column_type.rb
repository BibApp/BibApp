class ChangeAuthorAffiliationsColumnType < ActiveRecord::Migration
  def self.up
    change_column :citations, :author_address_affiliations, :text
  end

  def self.down
    change_column :citations, :author_address_affiliations, :string
  end
end
