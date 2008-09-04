class Keyword < ActiveRecord::Base
  has_many :keywordings
  has_many :works,
    :through => :keywordings

end
