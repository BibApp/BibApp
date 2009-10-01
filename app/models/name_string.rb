class NameString < ActiveRecord::Base
  require 'namecase'
  
  #### Associations ####
  has_many :works, 
    :through => :work_name_strings
  has_many :work_name_strings,
    :dependent => :delete_all
  has_many :people,
    :through => :pen_names
  has_many :pen_names
  
  #### Callbacks ####
  
  #### Named Scopes ####
  #Author and Editor name_strings
  named_scope :author, :conditions => ["role = ?", "Author"], :order => :position
  named_scope :editor, :conditions => ["role = ?", "Editor"], :order => :position
  
  def save_without_callbacks
    update_without_callbacks
  end
  
  def to_param
    param_name = name.gsub(" ", "_")
    param_name = name.gsub("-", "_")
    param_name = param_name.gsub(/[^A-Za-z0-9_]/, "")
    "#{id}-#{param_name}"
  end

  # Convert object into semi-structured data to be stored in Solr
  def to_solr_data
    "#{name}||#{id}"
  end 

  #return what looks to be the last name in this name string
  def last_name
    names = self.name.split(',')
    names[0]
  end
  
  class << self
    # return the first letter of each name, ordered alphabetically
    def letters
      find(
        :all,
        :select => 'DISTINCT SUBSTR(name, 1, 1) AS letter',
        :order  => 'letter'
      )
    end
    
    #Parse Solr data (produced by to_solr_data)
    # return NameString name and ID
    def parse_solr_data(name_string_data)
      data = name_string_data.split("||")
      name = data[0]
      id = data[1]  
      
      return name, id
    end
  end
end
