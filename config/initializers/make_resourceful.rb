#As currently structured make_resourceful includes this into ActiveModel::Base and for whatever reason it doesn't
#make it to ActiveRecord::Base. This does so and restores the ability of controllers to use make_resourceful's
#publish method.
#As such, this should be considered a kludge, though not a terrible one.
class ActiveRecord::Base
  include Resourceful::Serialize::Model
end
