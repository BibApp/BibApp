class Publisher < ActiveRecord::Base
    
  has_many :publications
  has_many :citations, :through => :publications
  has_many :unknown_status_citations, 
    :through      => :publications, 
    :source       => :citations,
    :class_name   => "Citation",
    :conditions   => "archive_status_id = 1"
  
  after_save :find_publications
  after_save :set_archive_statuses
  
  validates_presence_of :name
  # validates_numericality_of :sherpa_id
  
  def self.from_sherpa_api(host, page)
    require 'rubygems'
    require 'xmlsimple'
    require 'net/http'
    
    xml = Net::HTTP.get_response(host, page).response.body
    data = XmlSimple.xml_in(xml)

    data['publishers'][0]['publisher'].each do |pub|
      sherpa_id = pub['id'].to_i
      name = pub['name'][0]
      romeo_color = pub['romeocolour'][0]
      
      logger.debug("PubInspect: #{pub.inspect}")
      logger.debug("SherpaId: #{sherpa_id}")
      logger.debug("Name: #{name}")
      logger.debug("Color: #{romeo_color}")

      add = Publisher.find_or_create_by_sherpa_id(sherpa_id)
      add.update_attributes!({
        :name                   => name,
        :romeo_color           => romeo_color,
        :sherpa_id              => sherpa_id
      })
    end
  end
  
  def self.favorites
    favorite_publishers = Publisher.find_by_sql(
      ["select count(id) as count, publisher as full_name
      from citations 
      where publisher is not null
      group by publisher 
      order by count DESC
      limit 11"]
    )
  end
  
  def find_publications
    Publication.find(:all, :conditions => ["sherpa_id = ?", sherpa_id]).each do |p|
      p.publisher = self
      p.save
    end
  end
  
  def set_archive_statuses
    if archive_publisher_copy?
      unknown_status_citations.each do |c|
        c.archive_status_id = 2
        c.save
      end
    end
  end
end