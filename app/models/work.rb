require 'machine_name'
require 'stop_word_name_sorter'

class Work < ActiveRecord::Base
  include MachineName
  include StopWordNameSorter

  acts_as_authorizable #some actions on Works require authorization

  cattr_accessor :current_user

  # Information about a 'pre-verified' Contributorship
  # for a specific Person in the system
  # (This occurs when adding a Work directly to a Person).
  attr_accessor :preverified_person
  # For an import we need this flag in order to be able to create the contributorships at the right time
  attr_accessor :skip_create_contributorships

  serialize :scoring_hash

  #### Associations ####
  belongs_to :publication
  belongs_to :publisher

  has_many :name_strings, :through => :work_name_strings, :order => "position"

  has_many :work_name_strings, :order => "position", :dependent => :destroy

  has_many :people, :through => :contributorships,
           :conditions => ["contributorship_state_id = ?", Contributorship::STATE_VERIFIED]

  has_many :contributorships, :dependent => :destroy

  has_many :keywords, :through => :keywordings
  has_many :keywordings, :dependent => :destroy

  has_many :taggings, :as => :taggable, :dependent => :destroy
  has_many :tags, :through => :taggings
  has_many :users, :through => :taggings

  has_many :external_system_uris

  has_many :attachments, :as => :asset
  belongs_to :work_archive_state

  validates_presence_of :title_primary
  validates_numericality_of :publication_date_year, :allow_nil => true, :greater_than => 0
  validates_inclusion_of :publication_date_month, :in => 1..12, :allow_nil => true
  validates_each :publication_date_month do |record, attr, value|
    if value.present?
      unless record.publication_date_year
        record.errors.add attr, 'must have a year in order to supply a month'
      end
    end
  end
  validates_inclusion_of :publication_date_day, :in => 1..31, :allow_nil => true
  validates_each :publication_date_day do |record, attr, value|
    if value.present?
      if  record.publication_date_year and record.publication_date_month
        begin
          Date.new(record.publication_date_year, record.publication_date_month, record.publication_date_day)
        rescue
          record.errors.add attr, 'is not a valid day in the given year and month'
        end
      else
        record.errors.add attr, 'must have a year and a month to supply a day'
      end
    end
  end
  #### Named Scopes ####
  #Various Work Statuses
  STATE_IN_PROCESS = 1
  STATE_DUPLICATE = 2
  STATE_ACCEPTED = 3
  scope :in_process, where(:work_state_id => STATE_IN_PROCESS)
  scope :duplicate, where(:work_state_id => STATE_DUPLICATE)
  scope :accepted, where(:work_state_id => STATE_ACCEPTED)

  ARCHIVE_STATE_INITIAL = 1
  ARCHIVE_STATE_READY_TO_ARCHIVE = 2
  ARCHIVE_STATE_ARCHIVED = 3
  #Various Work Archival Statuses
  scope :ready_to_archive, where(:work_archive_state_id => ARCHIVE_STATE_READY_TO_ARCHIVE)
  scope :archived, where(:work_archive_state_id => ARCHIVE_STATE_ARCHIVED)

  TO_BE_BATCH_INDEXED = 1
  NOT_TO_BE_BATCH_INDEXED = 0

  scope :to_batch_index, where(:batch_index => TO_BE_BATCH_INDEXED)

  #Various Work Contribution Statuses
  scope :unverified, where('contributorships.contributorship_state_id = ?', Contributorship::STATE_UNVERIFIED)
  scope :verified, where('contributorships.contributorship_state_id = ?', Contributorship::STATE_VERIFIED)
  scope :denied, where('contributorships.contributorship_state_id = ?', Contributorship::STATE_DENIED)
  scope :visible, where('contributorships.hide = ?', false)

  scope :for_authority_publication,
        lambda { |authority_publication_id| where(:authority_publication_id => authority_publication_id) }

  scope :most_recent_first, order('updated_at DESC')
  scope :by_publication_date, order('publication_date_year DESC, publication_date_month DESC, publication_date_day DESC')

  def self.orphans
    (self.orphans_no_contributorships + self.orphans_denied_contributorships).uniq.sort { |a, b| a.title_primary <=> b.title_primary }
  end

  def self.orphans_no_contributorships
    self.order('title_primary').joins('LEFT JOIN contributorships ON works.id = contributorships.work_id').
        where(:contributorships => {:id => nil})
  end

  #The implementation may be improvable, but this only does 3 SQL calls. It could be done in one, but I'm not
  #sure how to accomplish that in the Rails query language.
  #We first find all works that have at least one denied contributorship. Then we load those works eager loading
  #all their contributorships and find the ones with all denied contributorships in code
  def self.orphans_denied_contributorships
    contributorships = Contributorship.denied.select("DISTINCT work_id")
    works = self.includes(:contributorships).where(:id => contributorships.collect { |c| c.work_id })
    works.select do |work|
      !work.contributorships.detect { |c| !c.denied? }
    end
  end

  #### Callbacks ####
  before_validation :set_initial_states, :on => :create
  after_create :after_create_actions
  before_save :before_save_actions
  after_save :after_save_actions

  # After Create only
  # (Note: after create callbacks *must* be placed in Work model,
  #  for faux-accessors to work properly)
  def after_create_actions
    create_work_name_strings
    create_keywords
    create_tags
  end

  def after_save_actions
    deduplicate
    create_contributorships unless self.skip_create_contributorships
  end

  def before_save_actions
    update_authorities
    update_scoring_hash
    update_archive_state
    update_machine_name
    update_sort_name
  end

  #### Serialization ####
  serialize :serialized_data

  ##### Work State Methods #####
  def in_process?
    self.work_state_id == STATE_IN_PROCESS
  end

  def is_in_process
    self.work_state_id = STATE_IN_PROCESS
  end

  def duplicate?
    self.work_state_id == STATE_DUPLICATE
  end

  def is_duplicate
    self.work_state_id = STATE_DUPLICATE
  end

  def accepted?
    self.work_state_id == STATE_ACCEPTED
  end

  def is_accepted
    self.work_state_id = STATE_ACCEPTED
  end

  # The field for work status in BibApp's Solr Index
  def self.solr_status_field
    return "status:"
  end

  # The Solr filter for accepted works...this is used by default, as
  # we don't want incomplete works to normally appear in BibApp
  def self.solr_accepted_filter
    return solr_status_field + STATE_ACCEPTED.to_s
  end

  # The Solr filter for duplicate works...these works are normally
  # hidden by BibApp, except to administrators
  def self.solr_duplicate_filter
    return solr_status_field + STATE_DUPLICATE.to_s
  end


  ##### Work Archival State Methods #####
  def init_archive_status
    self.work_archive_state_id = ARCHIVE_STATE_INITIAL
  end

  def has_init_archive_status?
    self.work_archive_state_id == ARCHIVE_STATE_INITIAL
  end

  def ready_to_archive?
    self.work_archive_state_id == ARCHIVE_STATE_READY_TO_ARCHIVE
  end

  def is_ready_to_archive
    self.work_archive_state_id = ARCHIVE_STATE_READY_TO_ARCHIVE
  end

  def archived?
    return true if self.work_archive_state_id == ARCHIVE_STATE_ARCHIVED
  end

  def is_archived
    self.work_archive_state_id = ARCHIVE_STATE_ARCHIVED
  end

  #batch indexing related
  def mark_indexed
    self.batch_index = NOT_TO_BE_BATCH_INDEXED
    self.save
  end

  ########## Methods ##########
  # Rule #1: Comment H-E-A-V-I-L-Y
  # Rule #2: Include @TODOs

  # List of all currently enabled Work Types
  def self.types
    # @TODO: Add each work subklass to this array
    # "Journal Article",
    # "Conference Proceeding",
    # "Book"
    # more...
    ["Artwork",
     "Book (Section)",
     "Book (Whole)",
     "Book Review",
     "Composition",
     "Conference Paper",
     "Conference Poster",
     "Conference Proceeding (Whole)",
     "Dissertation / Thesis",
     "Exhibition",
     "Grant",
     "Journal (Whole)",
     "Journal Article",
     "Monograph",
     "Patent",
     "Performance",
     "Presentation / Lecture",
     "Recording (Moving Image)",
     "Recording (Sound)",
     "Report",
     "Web Page",
     "Generic"]
  end

  def self.type_to_class(type)
    t = type.gsub(" ", "") #remove spaces
    t.gsub!("/", "") #remove slashes
    t.gsub!(/[()]/, "") #remove any parens
    t.constantize #change into a class
  end

  # Creates a new work from an attribute hash
  # Caller must check to see if there were any validation errors
  def self.create_from_hash(h, add_contributorships = true)
    klass = h[:klass]

    # Are we working with a legit SubKlass?
    klass = klass.constantize
    if klass.superclass != Work
      raise NameError.new("#{klass_type} is not a subclass of Work")
    end

    work = klass.new
    work.title_primary = h[:title_primary]
    work.skip_create_contributorships = !add_contributorships
    work.update_from_hash(h)
  end

  def denormalize_role(role)
    case role
      when 'Author'
        self.creator_role
      when 'Editor'
        self.contributor_role
      else
        role
    end
  end

  def delete_non_work_data(h)
    [:klass, :work_name_strings, :publisher, :publication, :issn_isbn, :keywords, :source, :external_id].each do |key|
      h.delete(key)
    end
    h
  end

  def publication_name_from_hash(h)
    case self.class.to_s
      when 'BookWhole', 'Monograph', 'JournalWhole', 'ConferenceProceedingWhole', 'WebPage'
        h[:title_primary] ? h[:title_primary] : 'Unknown'
      when 'BookSection', 'ConferencePaper', 'ConferencePoster', 'PresentationLecture', 'Report'
        h[:title_secondary] ? h[:title_secondary] : 'Unknown'
      when 'JournalArticle', 'BookReview', 'Performance', 'RecordingSound', 'RecordingMovingImage', 'Generic'
        h[:publication] ? h[:publication] : 'Unknown'
      else
        nil
    end
  end

  # Updates an existing work from an attribute hash
  # Caller must check to see if there were any validation errors.
  def update_from_hash(h)
    work_name_strings = (h[:work_name_strings] || []).collect do |wns|
      {:name => wns[:name], :role => self.denormalize_role(wns[:role])}
    end
    self.set_work_name_strings(work_name_strings)

    #If we are adding to a person, pre-verify that person's contributorship
    person = Person.find(h[:person_id]) if h[:person_id]
    self.preverified_person = person if person

    ###
    # Setting Publication Info, including Publisher
    ###
    publication_name = publication_name_from_hash(h)

    issn_isbn = h[:issn_isbn]
    if publication_name == 'Unknown' and issn_isbn.present?
      publication_name = "Unknown (#{issn_isbn})"
    end

    self.set_publication_info(:name => publication_name,
                              :issn_isbn => issn_isbn,
                              :publisher_name => h[:publisher])

    ###
    # Setting Keywords
    ###
    self.set_keyword_strings(h[:keywords])

    # Clean the hash of non-Work table data
    # Cleaning will prepare the hash for ActiveRecord insert
    self.delete_non_work_data(h)

    # When adding a work to a person, person_id causes work.save to fail
    h.delete(:person_id) if h[:person_id]

    #save remaining hash attributes
    saved = self.update_attributes(h)

    return self

  end


  # Deduplication: deduplicate Work records on save
  def deduplicate
    logger.debug("\n\n===DEDUPLICATE===\n\n")

    #Find all possible dupe candidates from Solr
    dupe_candidates = Index.possible_accepted_duplicate_works(self)
    logger.debug("\nDuplicates: #{dupe_candidates.size}")

    #Check if any duplicates found.
    #@TODO: Be smarter about this...first in probably shouldn't always win
    #IMPORTANT: we update fields directly here because this is in an after save callback and
    #we don't want to trigger another save when we make a change here!
    #Eventually (by Rails 3.2) we can just use update_column. For 3.0 we need to do something like this.
    if dupe_candidates.empty?
      self.class.where(:id => self.id).update_all(:work_state_id => STATE_ACCEPTED)
      #Only mark as duplicate if this work wasn't previously accepted
    elsif !self.accepted?
      self.class.where(:id => self.id).update_all(:work_state_id => STATE_DUPLICATE)
    end

    #@TODO: Is there a way that we can calculate the *canonical best*
    # version of a work? We've tried this in the past, but we need to do
    # it in a better way (e.g.  we don't end up accidentally re-marking things as
    # dupes that have previously been determined to not be dupes by a human)
  end

  def set_for_index_and_save
    self.batch_index = TO_BE_BATCH_INDEXED
    self.save
  end

  # Finds year of publication for this work
  def year
    publication_date_year
  end

  # Initializes an array of Keywords
  # and saves them to the current Work
  # Arguments:
  #  * array of keyword strings
  def set_keyword_strings(keyword_strings)
    keyword_strings ||= []
    keywords = keyword_strings.to_a.uniq.collect do |add|
      Keyword.find_or_initialize_by_name(add)
    end
    self.set_keywords(keywords)
    self.save
  end

  # Initializes an array of Tags
  # and saves them to the current Work
  # Arguments:
  #  * array of tag strings
  def set_tag_strings(tag_strings)
    tag_strings ||= []
    tags = tag_strings.to_a.uniq.collect do |add|
      Tag.find_or_initialize_by_name(add)
    end
    self.set_tags(tags)
    self.save
  end

  # Updates keywords for the current Work
  # If this Work is still a *new* record (i.e. it hasn't been created
  # in the database), then the keywords are just cached until the
  # Work is created.
  # Based on ideas at:
  #   http://blog.hasmanythrough.com/2007/1/22/using-faux-accessors-to-initialize-values
  #
  # Arguments:
  #  * array of Keywords
  def set_keywords(keywords)
    if self.new_record?
      @keywords_cache = keywords
    else
      self.update_keywordings(keywords)
    end
  end

  # Updates tags for the current Work
  # If this Work is still a *new* record (i.e. it hasn't been created
  # in the database), then the tags are just cached until the
  # Work is created.
  # Based on ideas at:
  #   http://blog.hasmanythrough.com/2007/1/22/using-faux-accessors-to-initialize-values
  #
  # Arguments:
  #  * array of Tags
  def set_tags(tags)
    if self.new_record?
      @tags_cache = tags
    else
      self.update_taggings(tags)
    end
  end

  # Updates Work name strings
  # (from a hash of "name" and "role" values)
  # and saves them to the current Work
  # Arguments:
  #  * hash {:name => "Donohue, T.", :role => "Author | Editor" }
  def set_work_name_strings(work_name_string_hash)
    if self.new_record?
      @work_name_strings_cache = work_name_string_hash
    else
      self.update_work_name_strings(work_name_string_hash)
    end
  end

  def set_publisher_from_name(publisher_name = nil)
    publisher_name = "Unknown" if publisher_name.blank?
    set_publisher = Publisher.find_or_create_by_name(:name => publisher_name, :romeo_color => 'unknown')
    self.set_initial_publisher(set_publisher)
    return set_publisher
  end

  def set_publication_from_name(name, issn_isbn, set_publisher)
    return unless name
    if issn_isbn.present?
      publication = Publication.find_or_create_by_name_and_issn_isbn_and_initial_publisher_id(:name => name,
                                                                                              :issn_isbn => issn_isbn.to_s, :initial_publisher_id => set_publisher.id)
    elsif set_publisher
      if set_publisher.name == 'Unknown'
        #try to look up a publisher from the publication name - if that doesn't work go ahead
        #and use the set_publisher
        publication = Publication.find_or_create_by_name(:name => name)
        if publisher = publication.publisher
          self.set_initial_publisher(publisher)
        else
          publication.publisher = set_publisher
        end
      else
        publication = Publication.find_or_create_by_name_and_initial_publisher_id(:name => name, :initial_publisher_id => set_publisher.id)
      end
    else
      publication = Publication.find_or_create_by_name(:name => name)
    end
    publication.save!
    set_initial_publication(publication)
  end


  # Initializes the Publication information
  # and saves it to the current Work
  # Arguments:
  #  * hash {:name => "Publication name",
  #          :issn_isbn => "Publication ISSN or ISBN",
  #          :publisher_name => "Publisher name" }
  #  (not all hash values need be set)
  def set_publication_info(publication_hash)
    logger.debug("\n\n===SET PUBLICATION INFO===\n\n")

    # If there is no publisher name, set to Unknown
    set_publisher = set_publisher_from_name(publication_hash[:publisher_name])
    set_publication_from_name(publication_hash[:name], publication_hash[:issn_isbn], set_publisher)
    self.save!
  end

  # All Works begin unverified
  def set_initial_states
    self.is_in_process
    self.init_archive_status
  end

  #Build a unique ID for this Work in Solr
  def solr_id
    "Work-#{id}"
  end

  # Generate a key based on title information
  # which can be used to determine if a Work is a duplicate
  def title_dupe_key
    # Title Dupe Key Format:
    # [Work.machine_name]||[Work.year]||[Publication.machine_name]
    if self.publication and self.publication.authority
      self.machine_name.to_s + "||" + self.year.to_s + "||" + self.publication.authority.machine_name.to_s
    end
  end

  # Generate a key based on Author/Editor information
  # which can be used to determine if a Work is a duplicate
  def name_string_dupe_key
    # NameString Dupe Key Format:
    # [First NameString.machine_name]||[Work.year]||[Work.type]||[Work.machine_name]
    if self.name_strings.present?
      self.name_strings[0].machine_name.to_s + "||" + self.year.to_s + "||" + self.type.to_s + "||" + self.machine_name.to_s
    end
  end

  # If the Work is accepted ensures Contributorships are set for each WorkNameString claim
  # associated with the Work.
  def create_contributorships
    if self.accepted?
      self.work_name_strings.each do |cns|
        # Find all People with a matching PenName claim
        claims = PenName.for_name_string(cns.name_string_id)
        # Find or create a Contributorship for each claim
        claims.each do |claim|
          Contributorship.find_or_create_by_work_id_and_person_id_and_pen_name_id_and_role(
              :work_id => self.id, :person_id => claim.person.id, :pen_name_id => claim.id, :role => cns.role)
        end
      end
    end
  end

  # Return a hash comprising all the Contributorship scoring methods
  def update_scoring_hash
    self.scoring_hash = {:year => self.publication_date_year,
                         :publication_id => self.publication_id,
                         :collaborator_ids => self.name_strings.collect { |ns| ns.id }, #there's an error if one tries to do this the natural way
                         :keyword_ids => self.keyword_ids}
  end

  def update_archive_state
    if self.archived_at
      self.is_archived
    elsif self.attachments.present?
      self.is_ready_to_archive
    elsif self.ready_to_archive?
      #if marked ready, but no attachments then revert to initial status
      self.init_archive_status
    end
  end

  #base machine name of work on title_primary
  def update_machine_name(force = true)
    if self.title_primary_changed? or self.machine_name.blank? or force
      self.machine_name = make_machine_name(self.title_primary)
    end
  end

  def update_authorities
    if self.publication
      self.publication_id = self.publication.authority_id
      self.publisher_id = self.publication.authority.publisher_id
    end
  end

  # Returns to Work Type URI based on the EPrints Application Profile's
  # Type vocabulary.  If the type is not available in the EPrints App Profile,
  # then the URI of the appropriate DCMI Type is returned.
  #
  # This is used for generating a SWORD package
  # which contains a METS file conforming to the EPrints DC XML Schema.
  #
  # For more info on EPrints App. Profile, and it's Type vocabulary, see:
  # http://www.ukoln.ac.uk/repositories/digirep/index/EPrints_Application_Profile
  #
  #Maps our Work Types to EPrints Application Profile Type URIs,
  # or to the DCMI Type Vocabulary URI (if not in EPrints App. Profile
  # Override in a subclass to assign a specific type_uri to that subclass
  # By default return nil
  #To get the full map used before breaking out into subclasses, which includes some types for
  #which there may not yet be subclasses, consult this method in version control history prior to 2011-02-28
  def type_uri
    return nil
  end

  # TODO As far as I can tell, to_s is only used in name and to_apa is only used in to_s
  # to_apa claims in a comment to have a real use, but I haven't checked it. So these methods
  # may be removable
  def name
    return self.to_s
  end

  #Convert Work into a String
  def to_s
    # Default to displaying Work in APA citation format
    to_apa
  end

  #Convert Work into a String in the APA Citation Format
  # This is currently used during generation of METS file
  # conforming to EPrints DC XML Schema for use with SWORD.
  # @TODO: There is likely a better way to do this more generically.
  # TODO: it may also not be doing what it should - what if there are both authors and editors
  # - it's not clear how they are distinguished.
  # TODO: in an ideal world this is just WorkExport.new.drive_csl('apa', self).html_safe
  # However, I'm not sure that the current csl and/or citeproc.rb does it well enough to be better
  # It may also be that how WorkExport feeds the work into the processor is a problem.
  # Note for future reference there is a ruby 1.9.2 citeproc-ruby that is actually active - look into it
  # when appropriate!
  # Note that we could, if necessary, deploy this as a service
  def to_apa
    String.new.tap do |citation_string|
      #---------------------------------------------
      # All APA Citation formats start out the same:
      #---------------------------------------------
      #Add authors
      append_apa_author_text(citation_string)

      #Add editors
      append_apa_editor_text(citation_string)

      #Publication year
      citation_string << " (#{self.publication_date_year})" if self.publication_date_year

      #Only add a period if the string doesn't currently end in a period.
      citation_string << ". " if !citation_string.match("\.\s*\Z")

      #Title
      citation_string << "#{self.title_primary}. " if self.title_primary

      #Now add in anything specific to the type of work, using a generic one defined in this model if
      #thee work type does not override.
      append_apa_work_type_specific_text!(citation_string)
    end
  end

  def append_apa_author_text(citation_string)
    append_apa_contributors_text(citation_string, self.work_name_strings.author.includes(:name_string))
  end

  def append_apa_editor_text(citation_string)
    append_apa_contributors_text(citation_string, self.work_name_strings.editor.includes(:name_string))
    citation_string << " (Ed.)." if self.work_name_strings.editor.count == 1
    citation_string << " (Eds.)." if self.work_name_strings.editor.count > 1
  end

  def append_apa_contributors_text(citation_string, collection)
    collection.first(5).each do |wns|
      name = wns.name_string.name
      name = ", #{name}" unless citation_string.blank?
      citation_string << name
    end
  end

  #defines a default behavior - override in subclass to specialize
  def append_apa_work_type_specific_text!(citation_string)
    citation_string << "#{self.publication.authority.name}, " if self.publication
    citation_string << self.volume if self.volume
    citation_string << "(#{self.issue})" if self.issue
    citation_string << ", " if self.start_page or self.end_page
    citation_string << self.start_page if self.start_page
    citation_string << "-#{self.end_page}" if self.end_page
    citation_string << "."
  end

  #Get all Author names on a Work, return as an array of hashes
  def authors
    self.work_name_strings.with_role(self.creator_role).includes(:name_string).collect do |wns|
      ns = wns.name_string
      {:name => ns.name, :id => ns.id}
    end
  end

  #Get all Editor Strings of a Work, return as an array of hashes
  def editors
    return [] if self.contributor_role == self.creator_role
    self.work_name_strings.with_role(self.contributor_role).includes(:name_string).collect do |wns|
      ns = wns.name_string
      {:name => ns.name, :id => ns.id}
    end
  end

  def self.creator_role
    raise RuntimeError, 'Subclass responsibility'
  end

  def self.contributor_role
    raise RuntimeError, 'Subclass responsibility'
  end

  def creator_role
    self.class.creator_role
  end

  def contributor_role
    self.class.contributor_role
  end

  def all_contributor_roles
    self.class.roles - [self.creator_role]
  end

  # In case there isn't a subklass open_url_kevs method
  def open_url_kevs
    open_url_kevs = Hash.new
    open_url_kevs[:format] = "&rft_val_fmt=info%3Aofi%2Ffmt%3Akev%3Amtx%3Ajournal"
    open_url_kevs[:genre] = "&rft.genre=article"
    open_url_kevs[:title] = "&rft.atitle=#{CGI.escape(self.title_primary)}"
    unless self.publication.nil?
      open_url_kevs[:source] = "&rft.jtitle=#{CGI.escape(self.publication.authority.name)}"
      open_url_kevs[:issn] = "&rft.issn=#{self.publication.issns.first[:name]}" if !self.publication.issns.empty?
    end
    open_url_kevs[:date] = "&rft.date=#{self.publication_date_string}"
    open_url_kevs[:volume] = "&rft.volume=#{self.volume}"
    open_url_kevs[:issue] = "&rft.issue=#{self.issue}"
    open_url_kevs[:start_page] = "&rft.spage=#{self.start_page}"
    open_url_kevs[:end_page] = "&rft.epage=#{self.end_page}"

    return open_url_kevs
  end

  #return OpenURL context string for this hash, e.g. for mets export of work
  #ignore any key that has a nil value
  def open_url_context_string
    self.open_url_context_hash.collect do |k, v|
      v ? URI.escape("&#{k}=#{v}") : nil
    end.compact.join('')
  end

  #return components to be incorporated into open_url_context_string
  #override in subclasses to add additional elements or change what happens
  #here
  def open_url_context_hash
    self.open_url_base_context_hash
  end

  def open_url_base_context_hash
    {'ctx_ver' => 'Z39.88-2004'}
  end

  def update_type_and_save(new_type)
    self[:type] = new_type
    self.save
  end

  def update_solr
    Index.update_solr(self)
  end

  def update_solr_no_autocommit
    Index.update_solr(self, false)
  end

  #The following methods are used by the IndexObserver, distinct from the other reindexing that happens.
  def require_reindex?
    !self.batch_index? and self.changed?
  end

  def reindex_after_save
    Index.update_solr(self)
  end

  def reindex_before_destroy
    Index.remove_from_solr(self)
  end

  def publication_date_string
    if self.publication_date_day
      sprintf('%04d-%02d-%02d', self.publication_date_year, self.publication_date_month, self.publication_date_day)
    elsif self.publication_date_month
      sprintf('%04d-%02d', self.publication_date_year, self.publication_date_month)
    elsif self.publication_date_year
      sprintf('%04d', self.publication_date_year)
    else
      ""
    end
  end

  protected

  # Update Keywordings - updates list of keywords for Work
  # Arguments:
  #   - Work object
  #   - collection of Keyword objects
  def update_keywordings(keywords)
    self.keywords = keywords || []
  end

  def update_taggings(tags)
    self.tags = tags || []
  end

  # Create keywords, after a Work is created successfully
  #  Called by 'after_create' callback
  def create_keywords
    #Create any initialized keywords and save to Work
    self.set_keywords(@keywords_cache) if @keywords_cache
  end


  def create_tags
    #Create any initialized tags and save to Work
    self.set_tags(@tags_cache) if @tags_cache
  end

  # Updates WorkNameStrings
  # (from a hash of "name" and "role" values)
  # and saves them to the given Work object
  # Arguments:
  #  * Work object
  #  * Array of hashes {:name => "Donohue, Tim", :role=> "Author | Editor" }
  def update_work_name_strings(name_strings_hash)
    return unless name_strings_hash
    #Remove *ALL* existing name_string(s).  We want to add them
    #all again from scratch, since the order of Authors/Editors *matters*
    self.work_name_strings.clear

    #Re-add all name string(s) to list
    name_strings_hash.flatten.each do |cns|
      machine_name = make_machine_name(cns[:name])
      name = cns[:name].strip
      name_string = NameString.find_or_create_by_machine_name(:machine_name => machine_name, :name => name)
      unless name_string.name == name
        name_string.name = name
        name_string.save!
      end
      self.work_name_strings.create(:name_string_id => name_string.id, :role => cns[:role])
    end
  end

# Create WorkNameStrings, after a Work is created successfully
#  Called by 'after_create' callback
  def create_work_name_strings
    #Create any initialized name_strings and save to Work
    self.set_work_name_strings(@work_name_strings_cache) if @work_name_strings_cache
  end

  def set_initial_publisher(publisher)
    self.publisher = publisher.authority
    self.initial_publisher_id = publisher.id
  end

  def set_initial_publication(publication)
    self.publication = publication.authority
    self.initial_publication_id = publication.id
  end

end
