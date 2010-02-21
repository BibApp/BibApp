class Tagging < ActiveRecord::Base
  belongs_to :user
  belongs_to :tag
  belongs_to :taggable,:polymorphic => true

  validates_presence_of :tag_id, :taggable_id
  
  def save_without_callbacks
    update_without_callbacks
  end
end