class Publication < ActiveRecord::Base

  attr_accessor :do_reindex
  #### Validations ####

  #### Associations ####

  belongs_to :publisher
  belongs_to :authority, :class_name => "Publication", :foreign_key => :authority_id
  has_many :works, :conditions => ["work_state_id = ?", Work::STATE_ACCEPTED] #accepted works

  has_many :identifyings, :as => :identifiable
  has_many :identifiers, :through => :identifyings

  scope :authorities, where("id = authority_id")
  scope :for_authority, lambda { |authority_id| where(:authority_id => authority_id) }
  scope :upper_name_like, lambda { |name| where('upper(name) like ?', name) }
  scope :order_by_upper_name, order('upper(name)')
  scope :order_by_name, order('name')

  # This is necessary due to very long titles for conference
  # proceedings. For example:
  # Cultivating the future based on science. Volume 1: Organic Crop
  # Production. Proceedings of the Second Scientific Conference of the
  # International Society of Organic Agriculture Research (ISOFAR), held at
  # the 16th IFOAM Organic World Conference in Cooperation with the
  # International Federation of Organic Agriculture Movements (IFOAM) and
  # the Consorzio ModenaBio in Modena, Italy, 18-20 June, 2008
  validates_length_of :name, :maximum => 255,
                      :too_long => "is too long (maximum is 255 characters): {{value}}"

  #### Callbacks ####
  after_create :after_create_actions
  before_create :before_create_actions
  before_save :before_save_actions
  after_save :update_authorities
  after_save :reindex, :if => :do_reindex

  #Called after create only
  def after_create_actions
    #Authority defaults to self
    self.authority_id = self.id
    self.save
  end

  def before_create_actions
    unless self.initial_publisher_id.nil?
      self.publisher_id = Publisher.find(self.initial_publisher_id).authority.id
    end
  end

  def before_save_actions
    self.update_machine_name
    self.parse_identifiers
  end

  #### Methods ####

  def validate_name
    "#{self.name} #{self.issn_isbn}".downcase.gsub(/[^a-zA-Z0-9]+/, "")
  end

  def publisher_name
    publisher.name if publisher
  end

  def publisher_name=(name)
    name ||= 'Unknown'
    self.publisher = Publisher.find_or_create_by_name(name) unless name.blank?
  end

  def isbns
    self.identifiers.where(:type => 'ISBN').collect { |isbn| {:name => isbn.name, :id => isbn.id} }
  end

  def issns
    self.identifiers.where(:type => 'ISSN').collect { |issn| {:name => issn.name, :id => issn.id} }
  end

  def parse_identifiers
    return if self.issn_isbn.blank?

    # Loop thru all publication issn_isbn values
    self.issn_isbn.each do |issn_isbn|

      # Field might be separated
      issn_isbn.split("; ").each do |identifier|

        # No spaces, no hyphens, no quotes -- @TODO: Do this better!
        identifier = identifier.strip.gsub(" ", "").gsub("-", "").gsub('"', "")

        # Init new Identifier
        parsed_identifiers = Identifier.parse(identifier)
        parsed_identifiers.each do |pi|
          klass, id = pi
          pub_id = Identifier.find_or_create_by_name_and_type(id, klass.id_type_string)
          unless self.identifiers.include?(pub_id)
            self.identifiers << pub_id
          end
        end

      end
    end
  end

  def to_param
    param_name = name.gsub(" ", "_")
    param_name = param_name.gsub(/[^A-Za-z0-9_]/, "")
    "#{id}-#{param_name}"
  end

  # Convert object into semi-structured data to be stored in Solr
  def to_solr_data
    "#{name}||#{id}" unless self.nil?
  end

  def solr_filter
    %Q(publication_id:"#{self.id}")
  end

  def form_select
    "#{name.first(100)}... - #{issn_isbn}"
  end

  def authority_for
    Publication.for_authority(self.id)
  end

  def authority_for_work_count
    Work.accepted.for_authority_publication(self.id).count
  end

  #Update authorities for related models, when Publication Authority changes
  # (called by after_save callback)
  def update_authorities
    # If Publication authority changed, we need to echo new authority key
    # to each related model.
    logger.debug("\n\nPub: #{self.id} | Auth: #{self.authority_id}\n\n")
    if (self.authority_id_changed? and self.authority_id != self.id) or self.publisher_id_changed?

      # Update publications
      logger.debug("\n\n===Updating Publications===\n\n")
      self.authority_for.each do |pub|
        pub.authority_id = self.authority_id
        pub.save
      end

      # Update works
      logger.debug("\n\n===Updating Works===\n\n")
      self.works.each do |work|
        work.publication_id = self.authority_id
        work.publisher_id = self.authority.publisher.authority_id
        work.set_for_index_and_save
      end
      self.do_reindex = true
    end
  end

  def reindex
    logger.debug("\n\n===Reindexing Works===\n\n")
    Index.batch_index
  end

  #Update Machine Name of Publication (called by after_save callback)
  def update_machine_name
    #Machine name only needs updating if there was a name change
    if self.name_changed?
      #Machine name is Name with:
      #  1. all punctuation/spaces converted to single space
      #  2. stripped of leading/trailing spaces and downcased
      self.machine_name = self.name.mb_chars.gsub(/[\W]+/, " ").strip.downcase
    end
  end

  # return the first letter of each name, ordered alphabetically
  def self.letters(upcase = nil)
    letters = self.select('DISTINCT SUBSTR(name, 1, 1) AS letter').order('letter').collect { |x| x.letter } - [' ']
    letters = letters.collect { |x| x.upcase } if upcase
    return letters
  end

  def self.update_multiple(pub_ids, auth_id)
    pub_ids.each do |pub|
      update = Publication.find_by_id(pub)
      update.authority_id = auth_id
      update.do_reindex = false
      update.save
    end
    Index.batch_index
  end

  #Parse Solr data (produced by to_solr_data)
  # return Publication name and ID
  def self.parse_solr_data(publication_data)
    if publication_data.blank?
      return nil, nil
    else
      name, id = publication_data.split("||")
      return name, id
    end
  end

end
