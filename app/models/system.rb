class System < ActiveRecord::Base
  self.abstract_class = true
	acts_as_authorizable

	#This System model has NO underlying database table.
	#It is used to give users System-wide roles (using Authorization plugin)

  #This class HAS NO INSTANCES!

    # has_admins? method, which checks to see if
    # there are any system-wide administrators
    def self.has_admins?
      self.has_admins.present?
    end

    # Find all system administrators
    def self.has_admins
      has_role("admin")
    end

    # has_editors? method, which checks to see if
    # there are any system-wide editors
    def self.has_editors?
      self.has_editors.present?
    end

    # Find all system editors
    def self.has_editors
      has_role("editor")
    end

    # Find all users having a system-based role of a particular name
    def self.has_role(name)
      role = Role.named(name).authorizable_type(System.name).authorizable_id(nil).first
      #return actual users, if role found
      role ? role.users : nil
    end

end
