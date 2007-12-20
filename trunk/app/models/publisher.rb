class Publisher < ActiveRecord::Base
  has_many :publications
  belongs_to :authority,
    :class_name => "Publisher",
    :foreign_key => :authority_id
  has_many :citations

  after_create do |publisher|
    publisher.authority_id = publisher.id
    publisher.save
  end
  
  def to_param
    param_name = name.gsub(" ", "_")
    param_name = param_name.gsub(/[^A-Za-z0-9_]/, "")
    "#{id}-#{param_name}"
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
end