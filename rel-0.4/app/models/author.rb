class Author < ActiveRecord::Base
  belongs_to :authority,
    :class_name => "Publication",
    :foreign_key => :authority_id
  has_many :citations, 
    :through => :authorships,
    :conditions => ["citation_state_id = 3"]
  has_many :authorships

  after_create do |author|
    author.authority_id = author.id
    author.save
  end

  def to_param
    param_name = name.gsub(" ", "_")
    param_name = param_name.gsub(/[^A-Za-z0-9_]/, "")
    "#{id}-#{param_name}"
  end
end
