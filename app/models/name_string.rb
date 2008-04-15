class NameString < ActiveRecord::Base
  has_many :citations, 
    :through => :citation_name_strings
  has_many :citation_name_strings

  def to_param
    param_name = name.gsub(" ", "_")
    param_name = param_name.gsub(/[^A-Za-z0-9_]/, "")
    "#{id}-#{param_name}"
  end

  def solr_id
    "NameString-#{id}"
  end
end
