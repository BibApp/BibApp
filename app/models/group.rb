class Group < ActiveRecord::Base
  has_many :people,
    :through => :memberships
  has_many :memberships

  def citations
    # @TODO: Do this the Rails way.
    self.people.collect{|p| p.citations.verified}.uniq.flatten
  end

  def to_param
    param_name = name.gsub(" ", "_")
    param_name = param_name.gsub(/[^A-Za-z0-9_]/, "")
    "#{id}-#{param_name}"
  end  
end