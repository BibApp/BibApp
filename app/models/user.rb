require 'digest/sha1'
class User < ActiveRecord::Base

  acts_as_authentic do |c|
    c.act_like_restful_authentication = true
  end

  # Authorization plugin
  acts_as_authorized_user
  acts_as_authorizable

  validates_presence_of :email
  validates_presence_of :password, :if => :require_password?
  validates_presence_of :password_confirmation, :if => :require_password?
  validates_length_of :password, :within => 4..40, :if => :require_password?
  validates_confirmation_of :password, :if => :require_password?
  validates_length_of :email, :within => 3..100
  validates_uniqueness_of :email, :case_sensitive => false

  # prevents a user from submitting a crafted form that bypasses activation
  # anything else you want your user to change should be added here.
  attr_accessible :email, :password, :password_confirmation

  #### Associations ####
  has_and_belongs_to_many :roles
  has_many :imports, :order => "created_at DESC"
  has_many :taggings, :dependent => :destroy
  has_many :tags, :through => :taggings
  has_many :users, :through => :taggings
  has_one :person
  has_many :authentications, :dependent => :destroy

  before_create :make_activation_code


  # Activates the user in the database.
  def activate
    @activated = true
    self.activated_at = Time.now.utc
    self.activation_code = nil
    save(:validate => false)
  end

  def active?
    # the existence of an activation code means they have not activated yet
    activation_code.nil?
  end

  # Returns true if the user has just been activated.
  def recently_activated?
    @activated
  end

  #Override has_role? in 'authorization' plugin
  # to support cascading roles based on the
  # role hierarchy defined for BibApp
  #
  # Returns if user has a specified role.
  def has_role?(role_name, authorizable_obj = nil)

    ##################################################
    # Cacade System Roles to everything!
    ##################################################
    unless authorizable_obj == System
      #If user is a System Admin,
      #then user has permissions to do ANYTHING 
      return true if has_role?("admin", System)

      #If user has this role System-Wide,
      #then this role should cascade to everything else!
      return true if has_role?(role_name, System)
    end

    ##################################
    # Setup Role Hierarchy for BibApp
    ##################################    
    #Cascade based on role hierarchy, so following is true:
    #  - All Admins are also Editors
    #  (@TODO: more roles may be added later)
    case role_name
      when "editor"
        # Users with 'admin' role are also 'editors'
        return true if has_role?("admin", authorizable_obj)
    end

    ##################################
    # Setup Class Hierarchy for BibApp
    ##################################    
    #Cascade based on Class hierarchy, so following is true:
    #  (1) All Roles on a Group cascade to the People in that group (and their Works)
    #  (2) All Roles on a Person cascade to their Works

    # If this is a Class object, then cascade based on class types
    if authorizable_obj.is_a? Class
      case authorizable_obj.to_s
        when 'Group'
          #If user has this role on any group in system, return true
          return true if has_any_role?(role_name, Group)
        when 'Person'
          #Group class role cascades to Person class
          return true if has_role?(role_name, Group)

          #If user has this role on any group in system, also return true
          return true if has_any_role?(role_name, Group)
        when 'Work'
          #Person class role cascades to Work class
          return true if has_role?(role_name, Person)

          #If user has this role on any person in system, also return true
          return true if has_any_role?(role_name, Person)
      end
    elsif authorizable_obj #else if instance of a Class
      case authorizable_obj.class.base_class.to_s
        when 'Person'
          #Get groups of this person, and look for role on each group
          authorizable_obj.groups.each do |group|
            return true if has_role?(role_name, group)
          end
        when 'Work'
          #Get all People associated with this Work, and look for role on each person
          authorizable_obj.people.each do |person|
            return true if has_role?(role_name, person)
          end
      end
    end

    #call overridden has_role? method for default settings
    super
  end


  #Checks to see if user has a specified role on ANY instance
  #of the passed in Class.
  #
  # (e.g.) has_any_role?('editor', Group) 
  #
  # The above would check if the user has the 'editor' role
  # on ANY group within the system.
  def has_any_role?(role_name, authorizable_class)

    ##################################################
    # Cacade System Roles to everything!
    ##################################################
    unless authorizable_class.to_s == 'System'
      #If user is a System Admin,
      #then user has permissions to do ANYTHING
      return true if has_role?("admin", System)

      #If user has this role System-Wide,
      #then this role should cascade to everything else!
      return true if has_role?(role_name, System)
    end

    #loop through user's roles, to look for any that match
    self.roles.each do |role|
      if (role.name == role_name) and (role.authorizable_type == authorizable_class.to_s)
        return true
      end
    end
    return false
  end

  # Checks to see if user explicitly has the specified role 
  # In other words, it doesn't check parent objects or take
  # into account any cascading of roles
  #
  # (e.g.) has_explicit_role?('editor', group) 
  #
  # The above would check if the user has the 'editor' role
  # specified explicitly for the group (and not at a system-wide level)
  def has_explicit_role?(role_name, authorizable_obj = nil)
    if authorizable_obj.class == Class
      self.roles.named(role_name).where(:authorizable_type => authorizable_obj.to_s,
                                        :authorizable_id => nil).exists?
    else
      self.roles.named(role_name).where(:authorizable_type => authorizable_obj.class.to_s,
                                        :authorizable_id => authorizable_obj.id).exists?
    end
  end

  def email_update_code(new_email)
    Digest::SHA1.digest(self.salt + ':' + new_email)
  end

  def apply_omniauth(omniauth)
    self.email = omniauth['user_info']['email']
    #other stuff to make a legal user
    if self.new_record?
      self.password = self.password_confirmation = User.random_password
    end

    # Update user info fetching from omniauth provider
    case omniauth['provider']
      when 'open_id'
        #do any extra work needed for openid
    end
  end
  
  #this is for Authorization gem
  def uri
    Authorization::Base::PERMISSION_DENIED_REDIRECTION
  end


  def self.random_password(len = 20)
    chars = (("a".."z").to_a + ("1".."9").to_a)- %w(i o 0 1 l 0)
    Array.new(len, '').collect { chars[rand(chars.size)] }.join
  end

  protected

  def require_password?
    crypted_password.blank? || !password.blank?
  end

  def make_activation_code
    self.activation_code = Digest::SHA1.hexdigest(Time.now.to_s.split(//).sort_by { rand }.join)
  end

  # return the first letter of each email, ordered alphabetically
  def self.letters
    self.select('DISTINCT SUBSTR(email, 1, 1) AS letter').order('letter').collect { |x| x.letter.upcase }.uniq
  end

end
