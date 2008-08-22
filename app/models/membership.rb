class Membership < ActiveRecord::Base
  belongs_to :person
  belongs_to :group
  
  acts_as_list  :scope => :person

end