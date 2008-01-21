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
  
  after_save do |publication|
    if publication.authority_id != publication.id
      publication.citations.each do |citation|
        citation.publication_id = publication.authority_id
        citation.save_without_callbacks
      end
    end
  end
  
  def to_param
    param_name = name.gsub(" ", "_")
    param_name = param_name.gsub(/[^A-Za-z0-9_]/, "")
    "#{id}-#{param_name}"
  end
  
  def form_select
    "#{name} - #{issn_isbn}"
  end
  
  class << self
    
    def update_multiple(pub_ids, auth_id)
      pub_ids.split(",").each do |pub|
        update = Publication.find_by_id(pub)
        update.authority_id = auth_id
        update.save
      end
    end
  end
end
