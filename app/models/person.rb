class Person < ActiveRecord::Base
  
  acts_as_authorizable  #some actions on people require authorization
 
  serialize :scoring_hash
  
  #### Associations ####
  
  has_many :name_strings, :through => :pen_names
  has_many :pen_names,
    :dependent => :delete_all
  
  has_many :groups, :through => :memberships, :conditions => ["groups.hide = ?", false], :order => "position"
  has_many :memberships,
    :dependent => :delete_all
  
  has_many :works, :through => :contributorships, :conditions => ["contributorships.contributorship_state_id = ?", 2]

  has_many :contributorships,
    :dependent => :delete_all
  
  has_one :image, :as => :asset,
    :dependent => :delete

  #### Validators ####

  validates_presence_of :uid
  
  #### Callbacks ####
 
  def after_create
    set_pen_names
  end

  def after_update
    set_pen_names
  end
  
  #Note: 'after_save' callback is located in 'person_observer.rb', to make
  # sure it is called *before* after_save in 'index_observer.rb'
  # (That way Person info is updated completely *before* re-indexing of works)
 
  #### Methods ####
  
  def save_without_callbacks
    update_without_callbacks
  end

  def set_pen_names
    # Accept Person.new form name field params and autogenerate pen_name associations 
    
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
    
    # First, Middle and Last are all cleaned the same, not DRY, but there may 
    # be a reason later to refactor. Removing periods and commas, replacing
    # with spaces and making sure double-spaces are reduced to single spaces
    
    # Clean first name "John"
    first_name = self.first_name.gsub(/[.,]/, "").gsub(/ +/, " ").strip.downcase

    # Clean middle name "William"
    middle_name = self.middle_name.gsub(/[.,]/, "").gsub(/ +/, " ").strip.downcase

    # Clean last name "Smith" 
    last_name = self.last_name.gsub(/[.,]/, "").gsub(/ +/, " ").strip.downcase
    
    # Collect the variant possibilities
    variants = Array.new
    variants << (last_name + " " + first_name + " " + middle_name).downcase.strip
    variants << (last_name + " " + first_name + " " + middle_name.first(1)).downcase.strip
    variants << (last_name + " " + first_name).downcase.strip
    variants << (last_name + " " + first_name.first(1) + " " + middle_name.first(1)).strip
    variants << (last_name + " " + first_name.first(1)).downcase.strip

    # Find or create
    variants.uniq.each do |v|
      ns = NameString.find_or_create_by_machine_name(v)
      self.name_strings << ns unless self.name_strings.include?(ns)
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
    self.works.sort!{ |a,b| b.updated_at <=> a.updated_at }.first
  end
  
  def to_param
    param_name = first_last.gsub(" ", "_")
    param_name = param_name.gsub(/[^A-Za-z0-9_]/, "")
    "#{id}-#{param_name}"
  end

  def groups_not
    all_groups = Group.find(:all, :order => "name")
    # TODO: do this right. The vector subtraction is dumb.
    return all_groups - groups
  end
  
  def name_strings_not
    suggestions = NameString.find(
      :all, 
      :conditions => ["name like ?", "%" + self.last_name + "%"],
      :order => :name
    )
    
    # TODO: do this right. The vector subtraction is dumb.
    return suggestions - name_strings
  end
  
  # Person Contributorship Calculation Fields
  def verified_publications
    Contributorship.verified.find_all_by_person_id(self.id,:include=>[:work])
  end
  
  def queue_update_scoring_hash
    self.send_later(:update_scoring_hash)
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
    
    known_years = vps.collect{|vp| 
                 if !vp.work.publication_date.nil?
                   vp.work.publication_date.year 
                 end
                   }.uniq
   known_years.delete(nil)

    
    known_publication_ids = vps.collect{|vp| vp.work.publication.id}.uniq
    known_collaborator_ids = vps.collect{|vp| vp.work.name_strings.collect{|ns| ns.id}}.flatten.uniq
    known_keyword_ids = vps.collect{|vp| vp.work.keywords.collect{|k| k.id}}.flatten.uniq
    
    # Return a hash comprising all the Contributorship scoring methods
    scoring_hash = {
      :years => known_years.sort, 
      :publication_ids => known_publication_ids,
      :collaborator_ids => known_collaborator_ids,
      :keyword_ids => known_keyword_ids
    }
    self.update_attribute(:scoring_hash, scoring_hash)
    
    # Now recalc all our unverified contributorships.
    self.send_later(:recalculate_unverified_contributorship_score)
  end
  
  #Update Machine Name of Person (called by after_save callback)
  def update_machine_name
    #Machine name only needs updating if there was a name change
    if self.first_name_changed? or self.middle_name_changed? or self.last_name_changed?
      #Machine name is Full Name with:
      #  1. all punctuation/spaces converted to single space
      #  2. stripped of leading/trailing spaces and downcased
      self.machine_name = self.full_name.chars.gsub(/[\W]+/, " ").strip.downcase
      self.save_without_callbacks
    end
  end
  
  #A person's image file
  def image_url
    if !self.image.nil?
      self.image.public_filename
    else
      "man.jpg"
    end
    
  end
  
  # Convert object into semi-structured data to be stored in Solr
  def to_solr_data
    "#{last_name}||#{id}||#{image_url}"
  end

  class << self
    # return the first letter of each name, ordered alphabetically
    def letters
      find(
        :all,
        :select => 'DISTINCT SUBSTR(last_name, 1, 1) AS letter',
        :order  => 'letter'
      )
    end
    
    #Parse Solr data (produced by to_solr_data)
    # return Person last_name, ID, and Image URL
    def parse_solr_data(person_data)
      data = person_data.split("||")
      last_name = data[0]
      id = data[1].to_i
      image_url = data[2]
      
      return last_name, id, image_url
    end

    def sort_by_most_recent_work(array_of_people)
      # For people with no works, time = Time.at(0)
      time = Time.at(0)
      array_of_people.sort! { |a,b|
        t1 = a.most_recent_work.nil? ? time : a.most_recent_work.updated_at
        t2 = b.most_recent_work.nil? ? time : b.most_recent_work.updated_at
        t2 <=> t1
      }
      array_of_people
    end

    def find_all_by_publisher_id(publisher_id)
      publisher = Publisher.find(publisher_id)
      works = publisher.works
      people = Array.new
      works.each do |work|
        people << work.people
      end
      people.flatten.uniq
    end

    def find_all_by_publication_id(publisher_id)
      publication = Publication.find(publisher_id)
      works = publication.works
      people = Array.new
      works.each do |work|
        people << work.people
      end
      people.flatten.uniq
    end

    def find_all_by_group_id(group_id)
      group = Group.find(group_id)
      group.people
    end

  end

end