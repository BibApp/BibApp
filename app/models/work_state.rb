#a Work's status in BibApp
class WorkState < ActiveRecord::Base
  #there are many Works in the same state
  has_many :works
end
