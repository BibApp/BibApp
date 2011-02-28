class Person < ActiveRecord::Base

  acts_as_authorizable #some actions on people require authorization

  serialize :scoring_hash

  #### Associations ####

  has_many :pen_names, :dependent => :destroy
  has_many :name_strings, :through => :pen_names

  has_many :memberships, :dependent => :destroy
  has_many :groups, :through => :memberships, :conditions => ["groups.hide = ?", false], :order => "position"

  has_many :works, :through => :contributorships,
           :conditions => ["contributorships.contributorship_state_id = ?", Contributorship::STATE_VERIFIED]

  has_many :contributorships, :dependent => :destroy

  has_one :image, :as => :asset, :dependent => :destroy

  #### Validators ####

  validates_presence_of :uid

  #### Callbacks ####
  after_create :set_pen_names
  after_update :set_pen_names
  before_save :update_machine_name

  #### Methods ##
  def set_pen_names
    # Accept Person.new form name field params and autogenerate pen_name associations
    # Find or create
    make_variant_names.uniq.each do |v|
      ns = NameString.find_or_create_by_machine_name(v)
      self.name_strings << ns unless self.name_strings.include?(ns)
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
    make_machine_name = lambda do |names|
      names.join(" ").downcase.strip
    end
    make_name = lambda do |first_status, middle_status, for_machine|
      names = []
      [[last_name, :full], [first_name, first_status], [middle_name, middle_status]].each do |name, status|
        names << name if status == :full
        names << abbreviate_name(name, for_machine) if status == :initial
      end
      name_function = for_machine ? make_machine_name : make_print_name
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
    "#{first_name} #{middle_name} #{last_name}"
  end

  def first_last
    "#{first_name} #{last_name}"
  end

  def last_first
    "#{last_name}, #{first_name}"
  end

  def last_first_middle
    "#{last_name}, #{first_name} #{middle_name}"
  end

  def most_recent_work
    self.works.most_recent_first.first
  end

  def to_param
    param_name = first_last.gsub(" ", "_")
    param_name = param_name.gsub(/[^A-Za-z0-9_]/, "")
    "#{id}-#{param_name}"
  end

  def groups_not
    all_groups = Group.order_by_name.all
    # TODO: do this right. The vector subtraction is dumb.
    return all_groups - groups
  end

  def name_strings_not
    suggestions = NameString.name_like(self.last_name).order_by_name.all
    # TODO: do this right. The vector subtraction is dumb.
    return suggestions - name_strings
  end

  # Person Contributorship Calculation Fields
  def verified_publications
    Contributorship.verified.find_all_by_person_id(self.id, :include=>[:work])
  end

  def queue_update_scoring_hash
    self.delay.update_scoring_hash
  end

  def recalculate_unverified_contributorship_score
    #re-calculate scores for all unverified contributorships of this Person        
    self.contributorships.unverified.each do |c|
      c.calculate_score
      Index.update_solr(c.work)
    end
  end

  def update_scoring_hash
    vps = self.verified_publications

    known_years = vps.collect do |vp|
      if !vp.work.publication_date.nil?
        vp.work.publication_date.year
      end
    end.uniq
    known_years.compact

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
      self.machine_name = self.full_name.mb_chars.gsub(/[\W]+/, " ").strip.downcase
    end
  end

  #A person's image file
  def image_url
    self.image ? self.image.public_filename : 'man.jpg'
  end

  #A person's group ids
  def comma_separated_group_ids
    self.group_ids.join(',')
  end

  # Convert object into semi-structured data to be stored in Solr
  def to_solr_data
    "#{last_name}||#{id}||#{image_url}||#{comma_separated_group_ids}"
  end

  def solr_filter
    %Q(person_id:"#{self.id}")
  end

  # TODO: do this the rails way.
  def publication_reftypes
    Person.find_by_sql(
        ["select type as ref_type,
      count(type) as count from works
      join contributorships on (works.id = contributorships.work_id)
      where contributorships.person_id = ?
      and contributorships.contributorship_state_id = ?
      group by type
      order by count desc", self.id, 2])
  end

  # TODO: do this the rails way.
  def keywords(limit = 15, bin_count = 5)
    keywords = Keyword.find_by_sql(
        ["select count(keywordings.keyword_id) as count, name
      from keywords
      join keywordings on (keywords.id = keywordings.keyword_id)
      join works on (keywordings.work_id = works.id)
      join contributorships on (works.id = contributorships.work_id)
      where contributorships.person_id = ?
      and contributorships.contributorship_state_id = ?
      group by name
      order by count DESC
      limit ?", self.id, 2, limit])

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
    select('DISTINCT SUBSTR(last_name, 1, 1) AS letter').order('letter')
  end

  #Parse Solr data (produced by to_solr_data)
  # return Person last_name, ID, and Image URL
  def self.parse_solr_data(person_data)
    last_name, id_as_string, image_url, unparsed_group_ids = person_data.split("||")
    id = id_as_string.to_i
    if unparsed_group_ids
      group_ids = unparsed_group_ids.split(",").collect { |g| g.to_i }
    else
      group_ids = []
    end
    return last_name, id, image_url, group_ids
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
    suffix = for_machine_name ? '' : '.'
    name.first + suffix
  end

end
