#Abstraction of LDAP functionality used by BibApp
require 'singleton'
require 'net/ldap'

class BibappLdapError < RuntimeError
end
class BibappLdapConfigError < BibappLdapError
end
class BibappLdapConnectionError < BibappLdapError
end
class BibappLdapTooManyResultsError < BibappLdapError
end

class BibappLdap
  include Singleton

  attr_accessor :config
  attr_accessor :connection_parameters

  def initialize(args = {})
    self.config = YAML::load(File.read("#{Rails.root}/config/ldap.yml"))[Rails.env]
    raise BibappLdapConfigError if self.config.blank?
    self.initialize_connection_parameters
  end

  def initialize_connection_parameters
    parameters = {:host => config['host'], :port => config['port'].to_i, :base => config['base']}
    if self.config['username'].present? and self.config['password'].present?
      parameters[:encryption] = :simple_tls
      parameters[:auth] = {:method => :simple, :username => config['username'], :password => config['password']}
    end
    self.connection_parameters = parameters
  end

  def get_connection
    Net::LDAP.new(self.connection_parameters).tap do |ldap|
      raise BibappLdapConnectionError unless ldap.bind
    end
  end

  def search(query)
    ldap = self.get_connection
    cn_filter = Net::LDAP::Filter.eq("#{self.config['cn']}", "*#{query}*")
    uid_filter = Net::LDAP::Filter.eq("#{self.config['uid']}", "*#{query}*")
    mail_filter = Net::LDAP::Filter.eq("#{self.config['mail']}", "*#{query}*")
    ldap.search(:filter => cn_filter | uid_filter | mail_filter).collect do |entry|
      clean(entry)
    end
  rescue BibappLdapError => e
    raise e
  rescue Exception => e
    if ldap.get_operation_result.code == 4
      raise BibappLdapTooManyResultsError
    elsif ldap.get_operation_result.code != 0
      raise BibappLdapError(ldap.get_operation_result.message)
    else
      raise BibappLdapError(e.message)
    end
  end

  def clean(entry)
    Hash.new.tap do |res|
      entry.each do |key, val|
        #res[key] = val[0]
        # map university-specific values
        if config.has_value? key.to_s
          k = config.index(key.to_s).to_sym
          res[k] = val[0]
          res[k] = NameCase.new(val[0]).nc! if [:sn, :givenname, :middlename, :generationqualifier, :displayname].include?(k)
          res[k] = val[0].titleize if [:title, :ou, :postaladdress].include?(k)
        end
      end
    end
  end


end