class Keyword < ActiveRecord::Base
  has_many :keywordings
  has_many :citations,
    :through => :keywordings

  def solr_id
    "Keyword-#{id}"
  end
end
