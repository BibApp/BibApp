class NameString < ActiveRecord::Base
  require 'namecase'
  
  #### Associations ####
  has_many :works, 
    :through => :work_name_strings
  has_many :work_name_strings
  has_many :people,
    :through => :pen_names
  has_many :pen_names
  
  #### Callbacks ####
  def after_create
    set_name
  end
  
  #### Named Scopes ####
  #Author and Editor name_strings
  named_scope :author, :conditions => ["role = ?", "Author"], :order => :position
  named_scope :editor, :conditions => ["role = ?", "Editor"], :order => :position
  
  def save_without_callbacks
    update_without_callbacks
  end
  
  def set_name
    # We use the machine_name field to find_or_create new NameString records
    # If we have a new NameString row, we need to "best-guess" the name field
    
    # Run the machine name through NameCase:
    # ex. "smith john w" => "Smith John W"
    name = NameCase.new(self.machine_name).nc
    
    # If we have an isolated letter, it's probably an initial
    # Split the string and measure each element, if it's one character long
    # we'll add a period to the initial:
    # ex. "Smith John W" => ["Smith", "John", "W."]
    name = name.split.collect{|c| c = c.size > 1 ? c : c+"."}
    
    # The first array element is going to be the last_name, so we'll give it
    # a comma:
    # ex. ["Smith,", "John", "W."]
    name[0] = name[0]+","
    
    # Last step, join on an empty space:
    # ex. "Larson, John W."
    self.name = name.join(" ")
    
    # Save the name, but avoid callbacks
    self.save_without_callbacks
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
