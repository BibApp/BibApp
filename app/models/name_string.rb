class NameString < ActiveRecord::Base
  has_many :citations, 
    :through => :citation_name_strings
  has_many :citation_name_strings
  has_many :people,
    :through => :pen_names
  has_many :pen_names

  def to_param
    param_name = name.gsub(" ", "_")
    param_name = param_name.gsub(/[^A-Za-z0-9_]/, "")
    "#{id}-#{param_name}"
  end

  def solr_id
    "NameString-#{id}"
  end
  
  #return what looks to be the last name in this name string
  def last_name
    names = self.name.split(',')
    names[0]
  end
end
