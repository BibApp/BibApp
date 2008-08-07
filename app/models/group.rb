class Group < ActiveRecord::Base
  acts_as_tree :order => "name"
  acts_as_authorizable  #some actions on groups require authorization
  
  has_many :people,
    :through => :memberships,
    :order => "last_name, first_name"
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

  # Convert object into semi-structured data to be stored in Solr
  def to_solr_data
    "#{name}||#{id}"
  end 

  class << self
    # return the first letter of each name, ordered alphabetically
    def letters
      find(
        :all,
        :select => 'DISTINCT SUBSTR(name, 1, 1) AS letter',
        :order  => 'letter',
        :conditions => ["hide = ?", false]
      )
    end
    
    #Parse Solr data (produced by to_solr_data)
    # return Group name and ID
    def parse_solr_data(group_data)
      data = group_data.split("||")
      name = data[0]
      id = data[1]  
      
      return name, id
    end
  end
end