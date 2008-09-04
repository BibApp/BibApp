class Publication < ActiveRecord::Base
  belongs_to :publisher
  belongs_to :authority,
    :class_name => "Publication",
    :foreign_key => :authority_id
  has_many :works, :conditions => ["work_state_id = 3"]
  
  after_create do |publication|
    publication.authority_id = publication.id
    publication.save
  end
  
  after_save do |publication|
    
    # If Publication authority changed, we need to echo new authority key
    # to each related model.
    
    logger.debug("\n\nPub: #{publication.id} | Auth: #{publication.authority_id}\n\n")
    if publication.authority_id != publication.id
      
      # Update publications
      logger.debug("\n\n===Updating Publications===\n\n")
      publication.authority_for.each do |pub|
        pub.authority_id = publication.authority_id
        pub.save
      end
      
      # Update works
      logger.debug("\n\n===Updating Works===\n\n")
      publication.works.each do |work|
        work.publication_id = publication.authority_id
        work.publisher_id = publication.publisher.authority_id
        work.save
      end
      
      #TODO: AsyncObserver
      Index.batch_index
    end
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

  def form_select
    "#{name.first(100)+"..."} - #{issn_isbn}"
  end

  def authority_for
    authority_for = Publication.find(
      :all, 
      :conditions => ["authority_id = ?", self.id]
    )
    return authority_for
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
  
    def update_multiple(pub_ids, auth_id)
      pub_ids.split(",").each do |pub|
        update = Publication.find_by_id(pub)
        update.authority_id = auth_id
        update.save
      end
    end
    
    #Parse Solr data (produced by to_solr_data)
    # return Publication name and ID
    def parse_solr_data(publication_data)
      data = publication_data.split("||")
      name = data[0]
      id = data[1]  
      
      return name, id
    end
  end
end
