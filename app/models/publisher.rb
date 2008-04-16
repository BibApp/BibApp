class Publisher < ActiveRecord::Base
  has_many :publications
  belongs_to :authority,
    :class_name => "Publisher",
    :foreign_key => :authority_id

  belongs_to :publisher_source,
    :class_name => "PublisherSource",
    :foreign_key => :source_id

  has_many :citations, :conditions => ["citation_state_id = 3"]

  before_validation_on_create :set_initial_states
  
  after_create do |publisher|
    publisher.authority_id = publisher.id
    publisher.save
  end
  
  after_save do |publisher|
    
    # If Publisher authority changed, we need to echo new authority key
    # to each related model.
    
    logger.debug("\n\nPub: #{publisher.id} | Auth: #{publisher.authority_id}\n\n")
    if publisher.authority_id != publisher.id
      
      # Update publishers
      logger.debug("\n\n===Updating Publishers===\n\n")
      publisher.authority_for.each do |pub|
        pub.authority_id = publisher.authority_id
        pub.save
      end
      
      # Update publications
      logger.debug("\n\n===Updating Publications===\n\n")
      publisher.publications.each do |publication|
        publication.publisher_id = publisher.authority_id
        publication.save
      end
      
      # Update citations
      logger.debug("\n\n===Updating Citations===\n\n")
      publisher.citations.each do |citation|
        citation.publisher_id = publisher.authority_id
        citation.save_and_set_for_index_without_callbacks
      end
      
      #@TODO: AsyncObserver
      Index.batch_index
    end
  end
  
  def set_initial_states
    self.source_id = 2 # Import Data
  end
  
  def to_param
    param_name = name.gsub(" ", "_")
    param_name = param_name.gsub(/[^A-Za-z0-9_]/, "")
    "#{id}-#{param_name}"
  end
  
  def solr_id
    "Publisher-#{id}"
  end
    
  def authority_for
    authority_for = Publisher.find(
      :all, 
      :conditions => ["authority_id = ?", self.id]
    )
    return authority_for
  end
    
  def self.from_sherpa_api
    # @TODO: Rewrite this using hpricot
    
    require 'hpricot'
    require 'open-uri'

    # SHERPA's API is not-cached! Opening the URI directly will likely 
    # produce a ruby net/http timeout.
    #
    # @TODO: 
    # 1. Offer a cached copy within /trunk?
    # 2. Add directions for placing a copy within /tmp/sherpa/publishers.xml
    
    data = Hpricot.XML(open("tmp/sherpa/publishers.xml"))

    (data/'publisher').each do |pub|
      sherpa_id = pub[:id].to_i
      name = (pub/'name').inner_html
      url = (pub/'homeurl').inner_html
      romeo_color = (pub/'romeocolour').inner_html

      add = Publisher.find_or_create_by_sherpa_id(sherpa_id)
      add.update_attributes!({
        :name         => name,
        :url          => url,
        :romeo_color  => romeo_color,
        :sherpa_id    => sherpa_id,
        :source_id    => 1           
      })
    end
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
        update = Publisher.find_by_id(pub)
        update.authority_id = auth_id
        update.save
      end
    end
  end
end