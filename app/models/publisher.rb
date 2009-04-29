class Publisher < ActiveRecord::Base
  
  #### Associations ####
  
  has_many :publications
  belongs_to :authority,
    :class_name => "Publisher",
    :foreign_key => :authority_id

  belongs_to :publisher_source,
    :class_name => "PublisherSource",
    :foreign_key => :source_id

  has_many :works, :conditions => ["work_state_id = ?", 3] #accepted works

  #### Callbacks ####
  
  before_validation_on_create :set_initial_states
  
  def after_create
    #Authority defaults to self
    self.authority_id = self.id
    self.save
  end
  
  #Note: 'after_save' callback is located in 'publisher_observer.rb', to make
  # sure it is called *before* after_save in 'index_observer.rb'
  # (That way Publisher info is updated completely *before* re-indexing of works)
  
  #### Methods ####
  
  def set_initial_states
    self.source_id = 2 # Import Data
  end
  
  def save_without_callbacks
    update_without_callbacks
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
  
  def authority_for
    authority_for = Publisher.find(
      :all, 
      :conditions => ["authority_id = ?", self.id]
    )
    return authority_for
  end
  
  #Update authorities for related models, when Publisher Authority changes
  # (called by after_save callback)
  def update_authorities
    # If Publisher authority changed, we need to echo new authority key
    # to each related model.
    logger.debug("\n\nPub: #{self.id} | Auth: #{self.authority_id}\n\n")
    if self.authority_id_changed? and self.authority_id != self.id
      
      # Update publishers
      logger.debug("\n\n===Updating Publishers===\n\n")
      self.authority_for.each do |pub|
        pub.authority_id = self.authority_id
        pub.save
      end
      
      # Update publications
      logger.debug("\n\n===Updating Publications===\n\n")
      self.publications.each do |publication|
        publication.publisher_id = self.authority_id
        publication.save
      end
      
      # Update Works
      logger.debug("\n\n===Updating Works===\n\n")
      self.works.each do |work|
        work.publisher_id = self.authority_id
        work.save
      end
    
    end
  end
  
  #Update Machine Name of Publisher (called by after_save callback)
  def update_machine_name
    #Machine name only needs updating if there was a name change
    if self.name_changed?
      #Machine name is Name with:
      #  1. all punctuation/spaces converted to single space
      #  2. stripped of leading/trailing spaces and downcased
      self.machine_name = self.name.chars.gsub(/[\W]+/, " ").strip.downcase
      self.save_without_callbacks
    end
  end

  #Return the year of the most recent publication
  def most_recent_year
    year = 0
    self.publications.each do |publication|
      publication.works.each do |work|
        if work.year.to_i > year
          year = work.year
        end
      end
    end
    return year > 0 ? year.to_s : ""
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
    
    def update_sherpa_data
      # @TODO: Rewrite this using hpricot

      require 'hpricot'
      require 'open-uri'

      # SHERPA's API is not-cached! Opening the URI directly will likely 
      # produce a ruby net/http timeout.
      #
      # @TODO: 
      # 1. Offer a cached copy within /trunk?
      # 2. Add directions for placing a copy within /tmp/sherpa/publishers.xml

      data = Hpricot.XML(open("public/sherpa/publishers.xml"))

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
    
    #Parse Solr data (produced by to_solr_data)
    # return Publisher name and ID
    def parse_solr_data(publisher_data)
      data = publisher_data.split("||")
      name = data[0]
      id = data[1]  
      
      return name, id
    end
    
  end
end