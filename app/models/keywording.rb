class Keywording < ActiveRecord::Base
  belongs_to :work
  belongs_to :keyword

  validates_presence_of :keyword_id, :work_id
  validates_uniqueness_of :keyword_id, :scope => :work_id
end
