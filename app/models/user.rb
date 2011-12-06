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
  validates_inclusion_of :default_locale, :in => I18n.available_locales

  # prevents a user from submitting a crafted form that bypasses activation
  # anything else you want your user to change should be added here.
  attr_accessible :email, :password, :password_confirmation, :default_locale

  #### Associations ####
  has_and_belongs_to_many :roles
  has_many :imports, :order => "created_at DESC"
  has_many :taggings, :dependent => :destroy
  has_many :tags, :through => :taggings
  has_many :users, :through => :taggings
  has_one :person
  has_many :authentications, :dependent => :destroy

  before_create :make_activation_code
  before_validation :ensure_default_locale

  # Activates the user in the database.
  def activate
    @activated = true
    self.activated_at = Time.now.utc
    self.activation_code = nil
    save_without_session_maintenance(:validate => false)
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
    # Cascade System Roles to everything!
    ##################################################
    return true if cascade_system_role?(role_name, authorizable_obj)

    ##################################
    # Setup Role Hierarchy for BibApp
    ##################################
    return true if cascade_role_name?(role_name, authorizable_obj)

    ##################################
    # Setup Class Hierarchy for BibApp
    ##################################
    if authorizable_obj.is_a?(Class)
      return true if cascade_role_class?(role_name, authorizable_obj)
    else
      return true if cascade_role_object?(role_name, authorizable_obj)
    end

    #call overridden has_role? method for default settings
    super
  end


  #If user is a System Admin, then user has permissions to do ANYTHING
  #If user has this role System-Wide, then this role should cascade to everything else!
  def cascade_system_role?(role_name, authorizable_object)
    return false if authorizable_object == System
    return has_role?('admin', System) || has_role?(role_name, System)
  end

  def cascade_role_name?(role_name, authorizable_object)
    case role_name
      #  - All Admins are also Editors
      when 'editor'
        return has_role?('admin', authorizable_object)
      else
        return false
    end
  end

  #Cascade based on Class hierarchy, so following is true:
  #  (1) All Roles on a Group cascade to the People in that group (and their Works)
  #  (2) All Roles on a Person cascade to their Works
  # If this is a Class object, then cascade based on class types
  def cascade_role_class?(role_name, authorizable_object)
    case authorizable_object.to_s
      when 'Group'
        return has_any_role?(role_name, Group)
      when 'Person'
        return has_role?(role_name, Group) || has_any_role?(role_name, Group)
      when 'Work'
        return has_role?(role_name, Person) || has_any_role?(role_name, Person)
      else
        return false
    end
  end

  def cascade_role_object?(role_name, authorizable_object)
    case authorizable_object.class.base_class.to_s
      when 'Person'
        #Look for role on each group associated with the person
        return authorizable_object.groups.detect {|group| has_role?(role_name, group)}
      when 'Work'
        #Look for role on each person associated with the work
        return authorizable_object.people.detect {|person| has_role?(role_name, person)}
      else
        return false
    end
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
    # Cascade System Roles to everything!
    ##################################################
    return true if cascade_system_role?(role_name, authorizable_class)

    #See if user has a role with the specified role_name and authorizable type
    return self.roles.where(:name => role_name, :authorizable_type => authorizable_class.to_s).exists?

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

  #make sure there is a default locale and that it is a symbol
  def ensure_default_locale
    self.default_locale ||= (I18n.locale || I18n.default_locale)
    self.default_locale = self.default_locale.to_sym
  end

  # return the first letter of each email, ordered alphabetically
  def self.letters
    self.select('DISTINCT SUBSTR(email, 1, 1) AS letter').order('letter').collect { |x| x.letter.upcase }.uniq
  end

end
