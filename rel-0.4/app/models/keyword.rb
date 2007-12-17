class Keyword < ActiveRecord::Base
  has_many :keywordings
  has_many :citations,
    :through => :keywordings
end
