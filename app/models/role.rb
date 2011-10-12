# Defines named roles for users that may be applied to
# objects in a polymorphic fashion. For example, you could create a role
# "moderator" for an instance of a model (i.e., an object), a model class,
# or without any specification at all.
class Role < ActiveRecord::Base
  has_and_belongs_to_many :users
  belongs_to :authorizable, :polymorphic => true

  scope :named, lambda {|name| where(:name => name)}
  scope :authorizable_type, lambda {|authorizable_type| where(:authorizable_type => authorizable_type)}
  scope :authorizable_id, lambda { |authorizable_id| where(:authorizable_id => authorizable_id)}

  #Provide a string description of this role, including whether
  #it is a System-Wide, Class, or object-level role.
  def description
    @description = self.name
    if self.authorizable_id
      @description << I18n.t('common.roles.description_class_and_name', :class => self.authorizable.class.model_name.human, :name => self.authorizable.name)
    elsif self.authorizable_type
      @description << I18n.t('common.roles.description_class', :class => self.authorizable_type.constantize.model_name.human)
    else
      @description << I18n.t('common.roles.description_generic')
    end
  end
end
