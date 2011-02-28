# Defines named roles for users that may be applied to
# objects in a polymorphic fashion. For example, you could create a role
# "moderator" for an instance of a model (i.e., an object), a model class,
# or without any specification at all.
class Role < ActiveRecord::Base
  has_and_belongs_to_many :users
  belongs_to :authorizable, :polymorphic => true

  #Provide a string description of this role, including whether
  #it is a System-Wide, Class, or object-level role.
  def description
    @description = self.name
    if self.authorizable_id
      @description << " of #{self.authorizable.class.to_s} '#{self.authorizable.name}'"
    elsif self.authorizable_type
      @description << " of #{self.authorizable_type}"
    else
      @description << " (generic role)"
    end
  end
end
