class Publication < ActiveRecord::Base
  
  belongs_to :publisher
      
  has_many :citations
  
  after_save :find_citations
  
  # validates_uniqueness_of :issn_isbn, :scope => :name
  
  def self.from_sherpa_api(host, page)
    require 'rubygems'
    require 'xmlsimple'
    require 'net/http'


    xml = Net::HTTP.get_response(host, page).response.body

    begin
    data = XmlSimple.xml_in(xml)
    
      if data['header'][0]['numhits'][0].to_i == 1+0 and data['publishers'][0].has_key?("publisher")
        issn_isbn = data['journals'][0]['journal'][0]['issn'][0]
        name      = data['journals'][0]['journal'][0]['jtitle'][0]
        sherpa_id = data['publishers'][0]['publisher'][0]['id']
      
        add = Publication.find_or_create_by_issn_isbn(issn_isbn)
        add.update_attributes({
          'sherpa_id'             => sherpa_id,
          'issn_isbn'             => issn_isbn,
          'name'                  => name
        })
      end
    rescue Exception => e
      logger.info("#{e.to_s}")
    end
  end

  def self.favorites
    favorite_publications = Publication.find_by_sql(
      ["select count(id) as count, periodical_full as full_name
      from citations 
      where periodical_full is not null
      group by periodical_full 
      order by count DESC
      limit 11"]
    )
  end
  
  private
  def find_citations
    Citation.find(:all, :conditions => ["issn_isbn = ?", issn_isbn]).each do |c|
      c.publication = self
      c.save
    end
  end
  
end
