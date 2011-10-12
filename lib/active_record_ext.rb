class ActiveRecord::Base

  def self.human_attribute_name_pl(key, args = {})
    self.human_attribute_name(key, args.reverse_merge(:count => 2))
  end

end

class ActiveModel::Name
  def human_pl(args = {})
    self.human(args.reverse_merge(:count => 2))
  end
end