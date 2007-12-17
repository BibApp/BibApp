class Keywording < ActiveRecord::Base
  belongs_to :citation
  belongs_to :keyword

  validates_presence_of :keyword_id, :citation_id
  validates_uniqueness_of :keyword_id, :scope => :citation_id
end
