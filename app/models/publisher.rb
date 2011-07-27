require 'lib/machine_name'
require 'lib/solr_helper_methods'
class Publisher < ActiveRecord::Base
  include MachineNameUpdater
  include SolrHelperMethods

  attr_accessor :do_reindex

  #### Associations ####

  has_many :publications
  belongs_to :authority, :class_name => "Publisher", :foreign_key => :authority_id

  belongs_to :publisher_source

  has_many :works, :conditions => ["work_state_id = ?", Work::STATE_ACCEPTED] #accepted works

  #### Callbacks ####

  scope :authorities, where("id = authority_id")
  scope :for_authority, lambda { |authority_id| where(:authority_id => authority_id) }
  scope :order_by_name, order('name')
  scope :order_by_upper_name, order('upper(name)')
  scope :upper_name_like, lambda { |name| where('upper(name) like ?', name) }
  scope :name_like, lambda { |name| where('name like ?', name) }

  before_validation :set_initial_states, :on => :create
  after_create :after_create_actions
  before_create :update_authorities
  before_save  :update_machine_name
  after_save :update_authorities
  after_save :reindex, :if => :do_reindex

  def after_create_actions
    #Authority defaults to self
    self.authority_id = self.id
    self.save
  end

  #### Methods ####

  SHERPA_SOURCE = 1
  IMPORT_SOURCE = 2
  def set_initial_states
    self.publisher_source_id = IMPORT_SOURCE # Import Data
  end

  # Convert object into semi-structured data to be stored in Solr
  def to_solr_data
    "#{name}||#{id}"
  end

  def solr_filter
    %Q(publisher_id:"#{self.id}")
  end

  def authority_for
    Publisher.where(:authority_id => self.id)
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

      # Update works
      logger.debug("\n\n===Updating Works===\n\n")
      self.publications.each do |publication|
        publication.works.each do |work|
          work.publisher_id = self.authority_id
          work.set_for_index_and_save
        end
      end

      self.do_reindex = true
    end
  end

  def reindex
    logger.debug("\n\n===Reindexing Works===\n\n")
    Index.batch_index
  end

  #Return the year of the most recent publication
  def most_recent_year
    max_year = self.publications.collect { |p| p.works }.flatten.collect { |w| w.year.to_i }.max
    return "" unless max_year
    return max_year > 0 ? max_year.to_s : ""
  end


  # return the first letter of each name, ordered alphabetically
  def self.letters(upcase = nil)
    letters = self.select('DISTINCT SUBSTR(name, 1, 1) AS letter').order('letter').collect {|x| x.letter}
    letters = letters.collect {|x| x.upcase} if upcase
    return letters
  end

  def self.update_multiple(pub_ids, auth_id)
    pub_ids.each do |pub|
      update = Publisher.find_by_id(pub)
      update.authority_id = auth_id
      update.do_reindex = false
      update.save
    end
    Index.batch_index
  end

  def self.update_sherpa_data

    # Hpricot chokes on UNICODE; use remxml instead
    #require 'hpricot'
    require 'rexml/document'

    require 'open-uri'
    require 'net/http'
    require 'config/personalize.rb'

    # First check that solr is running
    # We need it to be in order for the new publishers to be indexed
    begin
      n = Net::HTTP.new('localhost', SOLR_PORT)
      n.request_head('/').value

    rescue Errno::ECONNREFUSED, Errno::EBADF, Errno::ENETUNREACH #not responding
      puts "Warning: Updating Sherpa data requires Solr to be running. Exiting...\n"

    rescue Net::HTTPServerException #responding

      # SHERPA's API is not-cached! Opening the URI directly will likely
      # produce a ruby net/http timeout.
      #
      # Todo:
      # 1. Offer a cached copy within /trunk?
      # 2. Add directions for placing a copy within /tmp/sherpa/publishers.xml
      #
      # UPDATE:
      # The SHERPA API has gotten better, and requests are no longer timing
      # out. Unless those problems reëmerge, it's probably safe to download
      # the SHERPA data via net/http.

      #data = Hpricot.XML(open("public/sherpa/publishers.xml"))
      sherpa_response = Net::HTTP.get_response(URI.parse($SHERPA_API_URL))
      data = REXML::Document.new(sherpa_response.body)

      data.elements.each('/romeoapi/publishers/publisher') do |pub|
        sherpa_id = pub.attributes['id']
        name = pub.elements['name'].text
        url = pub.elements['homeurl'].text
        romeo_color = pub.elements['romeocolour'].text

        add = Publisher.find_or_create_by_sherpa_id(sherpa_id)
        add.update_attributes!({
                                   :name => name,
                                   :url => url,
                                   :romeo_color => romeo_color,
                                   :sherpa_id => sherpa_id,
                                   :publisher_source_id => SHERPA_SOURCE
                               })
        t = true
      end

    rescue
      puts "Unexpected Error: #{$!.class.to_s} #{$!}"
      raise
    end

  end

  #Parse Solr data (produced by to_solr_data)
  # return Publisher name and ID
  def self.parse_solr_data(publisher_data)
    if publisher_data
      name, id = publisher_data.split("||")
    else
      name = "Unknown"
      id = nil
    end
    return name, id
  end

end