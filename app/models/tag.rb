class Tag < ActiveRecord::Base
  has_many :taggings, :dependent => :delete_all
  has_many :tags, :through => :taggings
  has_many :users, :through => :taggings

  def solr_id
    "Tag-#{id}"
  end
end