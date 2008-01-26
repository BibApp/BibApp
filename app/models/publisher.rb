class Publisher < ActiveRecord::Base
  has_many :publications
  belongs_to :authority,
    :class_name => "Publisher",
    :foreign_key => :authority_id
  has_many :citations, :conditions => ["citation_state_id = 3"]

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
      
      #TODO: AsyncObserver
      Index.batch_index
    end
  end
  
  def to_param
    param_name = name.gsub(" ", "_")
    param_name = param_name.gsub(/[^A-Za-z0-9_]/, "")
    "#{id}-#{param_name}"
  end
  
  def authority_for
    authority_for = Publisher.find(
      :all, 
      :conditions => ["authority_id = ?", self.id]
    )
    return authority_for
  end
    
  def self.from_sherpa_api(host, page)
    require 'rubygems'
    require 'xmlsimple'
    require 'net/http'
    
    xml = Net::HTTP.get_response(host, page).response.body
    data = XmlSimple.xml_in(xml)

    data['publishers'][0]['publisher'].each do |pub|
      sherpa_id = pub['id'].to_i
      name = pub['name'][0]
      url = pub['homeurl'][0]
      romeo_color = pub['romeocolour'][0]
      
      logger.debug("PubInspect: #{pub.inspect}")
      logger.debug("SherpaId: #{sherpa_id}")
      logger.debug("Name: #{name}")
      logger.debug("Color: #{romeo_color}")

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
  
    def update_multiple(pub_ids, auth_id)
      pub_ids.split(",").each do |pub|
        update = Publisher.find_by_id(pub)
        update.authority_id = auth_id
        update.save
      end
    end
  end
end