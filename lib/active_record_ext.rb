class ActiveRecord::Base

  def self.human_name_pl(args = {})
    self.human_name(args.reverse_merge(:count => 2))
  end

  def self.human_attribute_name_pl(key, args = {})
    self.human_attribute_name(key, args.reverse_merge(:count => 2))
  end

end