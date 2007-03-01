class Appointment < ActiveRecord::Base
  belongs_to :person,
    :foreign_key => "person_id"
  belongs_to :position,
    :foreign_key => "position_id"
end
