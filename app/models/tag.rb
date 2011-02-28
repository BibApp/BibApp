class Tag < ActiveRecord::Base
  has_many :taggings, :dependent => :destroy
  has_many :tags, :through => :taggings
  has_many :users, :through => :taggings

  scope :order_by_name, order('name')
end