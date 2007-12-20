class Publication < ActiveRecord::Base
  belongs_to :publisher
  belongs_to :authority,
    :class_name => "Publication",
    :foreign_key => :authority_id
  has_many :citations, :conditions => ["citation_state_id = 3"]
  
  after_create do |publication|
    publication.authority_id = publication.id
    publication.save
  end

  def to_param
    param_name = name.gsub(" ", "_")
    param_name = param_name.gsub(/[^A-Za-z0-9_]/, "")
    "#{id}-#{param_name}"
  end
  
  def form_select
    "#{name} - #{issn_isbn}"
  end
end
