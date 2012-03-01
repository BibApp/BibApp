require 'bibapp_ldap'
require 'machine_name'
require 'solr_helper_methods'
require 'solr_updater'

class Person < ActiveRecord::Base
  include MachineName
  include SolrHelperMethods
  include SolrUpdater

  acts_as_authorizable #some actions on people require authorization

  serialize :scoring_hash

  #### Associations ####

  has_many :pen_names, :dependent => :destroy
  has_many :name_strings, :through => :pen_names

  has_many :memberships, :dependent => :destroy
  has_many :groups, :through => :memberships, :conditions => ["groups.hide = ?", false], :order => 'position'

  has_many :works, :through => :contributorships,
           :conditions => ["contributorships.contributorship_state_id = ?", Contributorship::STATE_VERIFIED]

  has_many :contributorships, :dependent => :destroy

  has_one :image, :as => :asset, :dependent => :destroy
  belongs_to :user

  #### Validators ####

  validates_presence_of :uid

  #### Sanitize HTML ####
  html_fragment :research_focus, :scrub => :escape

  #### Callbacks ####
  before_create :make_active
  after_create :set_pen_names
  after_update :set_pen_names
  before_save :update_machine_name
  after_save :update_memberships_end_dates

  #### Methods ##
  def set_pen_names
    # Accept Person.new form name field params and autogenerate pen_name associations
    # Find or create
    names = make_variant_names.uniq
    existing_name_strings = NameString.where(:machine_name => names.collect { |n| n[:machine_name] }).all
    existing_names = existing_name_strings.collect { |n| n.machine_name }
    new_name_strings = (names.reject { |n| existing_names.include?(n[:machine_name]) }).collect do |v|
      NameString.find_or_create_by_machine_name(v)
    end
    (existing_name_strings + new_name_strings).each do |ns|
      PenName.find_or_create_by_person_id_and_name_string_id(:person_id => self.id, :name_string_id => ns.id)
    end
  end

  def make_variant_names
    # Example is me...
    # first_name   => "John"
    # middle_name  => "William"
    # last_name    => "Smith"

    # Generate machine_name and pretty_name (name) for each machine_name
    # => Smith, John William => smith john william
    # => Smith, John W       => smith john w
    # => Smith, John         => smith john
    # => Smith, J W          => smith j w
    # => Smith, J            => smith j
    # Clean each name part

    first_name = self.clean_name(self.first_name)
    middle_name = self.clean_name(self.middle_name)
    last_name = self.clean_name(self.last_name)

    make_print_name = lambda do |names|
      last_name = names.shift
      "#{last_name}, #{names.join(" ")}".strip
    end
    my_make_machine_name = lambda do |names|
      make_machine_name_from_array(names)
    end
    make_name = lambda do |first_status, middle_status, for_machine|
      names = []
      [[last_name, :full], [first_name, first_status], [middle_name, middle_status]].each do |name, status|
        names << name if status == :full
        names << abbreviate_name(name, for_machine) if status == :initial
      end
      name_function = for_machine ? my_make_machine_name : make_print_name
      name_function.call(names)
    end
    #Call with each argument as :full to use the full name, :initial to use the first character, and :omit
    #to not use it
    variant_hash = lambda do |first_status, middle_status|
      {:name => make_name.call(first_status, middle_status, false),
       :machine_name => make_name.call(first_status, middle_status, true)}
    end

    # Collect the variant possibilities
    Array.new.tap do |variants|
      variants << variant_hash.call(:full, :full) # Smith, John William | smith john william
      variants << variant_hash.call(:full, :initial) # Smith, John W. | smith john w
      variants << variant_hash.call(:full, :omit) # Smith, John | smith john
      variants << variant_hash.call(:initial, :initial) # Smith, J. W. | smith j w
      variants << variant_hash.call(:initial, :omit) # Smith, J. | smith j
    end
  end

  def name
    first_last
  end

  def full_name
    self.join_names(' ', first_name, middle_name, last_name)
  end

  def first_last
    self.join_names(' ', first_name, last_name)
  end

  def last_first
    self.join_names(', ', last_name, first_name)
  end

  def last_first_middle
    given_name = self.join_names(' ', first_name, middle_name)
    self.join_names(', ', last_name, given_name)
  end

  def most_recent_work
    self.works.most_recent_first.first
  end

  def groups_not
    Group.where("id NOT in (?)", self.group_ids).order_by_name.all
  end

  def name_strings_not
    NameString.name_like(self.last_name).where("id NOT in (?)", self.name_string_ids).order_by_name.all
  end

  # Person Contributorship Calculation Fields
  def verified_publications
    Contributorship.verified.where(:person_id => self.id).includes(:work => [:publication, :name_strings, :keywords]).all
  end

  def queue_update_scoring_hash
    self.delay.update_scoring_hash
  end

  def recalculate_unverified_contributorship_score
    #re-calculate scores for all unverified contributorships of this Person
    self.contributorships.unverified.each do |c|
      c.calculate_score(self.scoring_hash)
      Index.update_solr(c.work)
    end
  end

  def update_scoring_hash
    vps = self.verified_publications

    known_years = vps.collect do |vp|
      vp.work.publication_date_year
    end.uniq.compact

    known_publication_ids = vps.collect { |vp| vp.work.publication.id if vp.work.publication }.uniq.compact
    known_collaborator_ids = vps.collect { |vp| vp.work.name_strings.collect { |ns| ns.id } }.flatten.uniq
    known_keyword_ids = vps.collect { |vp| vp.work.keywords.collect { |k| k.id } }.flatten.uniq

    # Return a hash comprising all the Contributorship scoring methods
    scoring_hash = {
        :years => known_years.sort,
        :publication_ids => known_publication_ids,
        :collaborator_ids => known_collaborator_ids,
        :keyword_ids => known_keyword_ids
    }
    self.update_attribute(:scoring_hash, scoring_hash)

    # Now recalc all our unverified contributorships.
    self.delay.recalculate_unverified_contributorship_score
  end

  #Update Machine Name of Person (called by after_save callback)
  def update_machine_name
    #Machine name only needs updating if there was a name change
    if self.first_name_changed? or self.middle_name_changed? or self.last_name_changed?
      #Machine name is Full Name with:
      #  1. all punctuation/spaces converted to single space
      #  2. stripped of leading/trailing spaces and downcased
      self.machine_name = make_machine_name(self.full_name)
    end
  end

  #A person's image file
  def image_url
    (self.image ? self.image.url : 'man.jpg')
  rescue
    'man.jpg'
  end

  #A person's group ids
  def comma_separated_group_ids
    self.group_ids.join(',')
  end

  #Is the person active? Any blanks will be interpreted as false.
  def person_active
    self.active?.to_s
  end

  def make_active
    self.active = true
  end

  #A person's research focus.
  #You get stack overflow without the dump method, I assume
  #due to the new line or quote characters in the text
  def person_research_focus
    self.research_focus.dump
  end

  # Convert object into semi-structured data to be stored in Solr
  def to_solr_data
    "#{last_name}||#{id}||#{image_url}||#{comma_separated_group_ids}||#{person_active}||#{person_research_focus}"
  end

  def solr_filter
    %Q(person_id:"#{self.id}")
  end

  def get_associated_works
    self.works.verified
  end

  def require_reindex?
    self.first_name_changed? or self.last_name_changed? or self.machine_name_changed? or self.active_changed? or self.research_focus_changed?
  end

  def publication_reftypes
    Work.select('type, count(type)').joins(:contributorships).
        where(:contributorships => {:person_id => self.id, :contributorship_state_id => Contributorship::STATE_VERIFIED}).
        group('type').order('count desc')
  end

  def keywords(limit = 15, bin_count = 5)
    keywords = Keyword.select('count(keywordings.keyword_id) as count, name').
        joins({:keywordings => {:work => :contributorships}}).
        where(:keywordings => {:work => {:contributorships => {:person_id => self.id, :contributorship_state_id => Contributorship::STATE_VERIFIED}}}).
        group('name').order('count DESC').limit(limit)

    max_kw_freq = bin_count.to_i
    max_kw = keywords.max { |a, b| a.count.to_i <=> b.count.to_i }
    max_kw_freq = max_kw.count.to_i if max_kw and max_kw.count.to_i > max_kw_freq

    keywords.map do |kw|
      bin = ((kw.count.to_f * bin_count.to_f)/max_kw_freq).ceil
      kw.count = bin
    end

    return keywords.sort { |a, b| a.name <=> b.name }

  end

  # return the first letter of each name, ordered alphabetically
  def self.letters
    select('DISTINCT SUBSTR(last_name, 1, 1) AS letter').order('letter').collect { |x| x.letter.upcase }
  end

  #called by after_save callback
  # @TODO Find bad dates, e.g. 0001-01-01, and replace them.
  def update_memberships_end_dates
    #Update memberships when person becomes inactive
    if self.active_change == [true, false]
      self.logger.info("#{self.changes}")
      self.memberships.update_all({:end_date => Time.now}, ['end_date IS NULL'])
    end
  end

  #Parse Solr data (produced by to_solr_data)
  # return Person last_name, ID, Image URL, Active status, and research_focus
  def self.parse_solr_data(person_data)
    last_name, id_string, image_url, group_ids_string, is_active, research_focus = person_data.split("||")
    id = id_string.to_i

    if group_ids_string.blank?
      group_ids = []
    else
      group_ids = group_ids_string.split(",").collect { |g| g.to_i }
    end

    return last_name, id, image_url, group_ids, is_active, research_focus
  end

  def self.sort_by_most_recent_work(array_of_people)
    # For people with no works, time = Time.at(0)
    time = Time.at(0)
    array_of_people.sort! do |a, b|
      t1 = a.most_recent_work.nil? ? time : a.most_recent_work.updated_at
      t2 = b.most_recent_work.nil? ? time : b.most_recent_work.updated_at
      t2 <=> t1
    end
  end

  protected

  def clean_name(name)
    name.gsub(/[.,]/, "").gsub(/ +/, " ").strip
  end

  def abbreviate_name(name, for_machine_name = false)
    return "" if name.blank?
    suffix = for_machine_name ? '' : '.'
    name.first + suffix
  end

  #join the given strings together with the given separator, ignoring any blanks.
  def join_names(separator, *names)
    names.select { |x| x.present? }.join(separator)
  end

end
