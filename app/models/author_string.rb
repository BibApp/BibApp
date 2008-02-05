class AuthorString < ActiveRecord::Base
  has_many :citations, 
    :through => :citation_author_strings
  has_many :citation_author_strings

  def to_param
    param_name = name.gsub(" ", "_")
    param_name = param_name.gsub(/[^A-Za-z0-9_]/, "")
    "#{id}-#{param_name}"
  end
end
