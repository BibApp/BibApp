require 'set'
class Contributorship < ActiveRecord::Base

  attr_accessor :skip_refresh_contributorships

  STATE_UNVERIFIED = 1
  STATE_VERIFIED = 2
  STATE_DENIED = 3

  #### Associations ####
  belongs_to :person
  belongs_to :work
  belongs_to :pen_name

  #### Named Scopes ####
  #Various Contributorship statuses
  scope :unverified, where(:contributorship_state_id => STATE_UNVERIFIED)
  scope :verified, where(:contributorship_state_id => STATE_VERIFIED)
  scope :denied, where(:contributorship_state_id => STATE_DENIED)
  # TODO: For now we don't want editors showing up as contributors
  #   although in the future we might want them to show up for whole
  #   conference proceedings, entire books, et cetera
  scope :visible, where(:hide => false, :role => "Author")
  #By default, show all verified, visible contributorships
  scope :to_show, where(:hide => false, :contributorship_state_id => STATE_VERIFIED)
  #All contributorships for a specified work or person
  scope :for_work, lambda { |work_id| where(:work_id => work_id) }
  scope :for_person, lambda { |person_id| where(:person_id => person_id) }

  #### Validations ####
  validates_presence_of :person_id, :work_id, :pen_name_id
  validates_uniqueness_of :work_id, :scope => :person_id

  #### Callbacks ####
  before_validation :set_initial_states, :on => :create
  after_create :calculate_initial_score
  after_save :after_save_actions

  def after_save_actions
    logger.debug("\n=== REFRESHING ===\n")
    self.refresh_contributorships
  end

  ## Note: no 'after_destroy' is necessary here, as PenNameObserver
  ## takes care of updating Solr before destroying Contributorships
  ## associated with a PenName.

  ##### Contributorship State Methods #####
  def set_initial_states
    # All Contributions start with:
    # * state - "Unverified"
    # * hide  - 0 (false)
    # * score - 0 (zero)
    self.contributorship_state_id = STATE_UNVERIFIED
    self.hide = false
    self.score = 0
  end

  def unverified?
    self.contributorship_state_id == STATE_UNVERIFIED
  end

  def unverify_contributorship
    self.contributorship_state_id = STATE_UNVERIFIED
    # if the contributorship is going from denied -> unverified
    # we need it to be unhidden
    self.hide = false
    self.save
  end

  def verified?
    self.contributorship_state_id == STATE_VERIFIED
  end

  def verify_contributorship
    self.contributorship_state_id = STATE_VERIFIED
    # if the contributorship is going from denied -> verified
    # we need it to be unhidden
    self.hide = false
    self.save
  end

  def denied?
    self.contributorship_state_id == STATE_DENIED
  end

  def deny_contributorship
    # Denying a Contributorship requires following
    # 1. Set state to "Denied"
    # 2. Set hide to "true"
    # 3. Set score to "zero"
    self.contributorship_state_id = STATE_DENIED
    self.hide = true
    self.score = 0
    self.save
  end

  def visible?
    self.hide == false
  end


  ########## Methods ##########
  def calculate_score(person_scoring_hash = nil)

    # Build the calculated Contributorship.score attribute--a rough
    # guess whether we think the Person has written the Work
    #
    # Field           Value   Scoring Algorithm
    # ---------------------------------------------
    # Years            25      If matches = 25 pts
    # Publications     25      If matches = 25 pts
    # Collaborators    25      (25/total) * matching
    # Keywords         25      (25/total) * matching

    # Observations (EL):
    # Looks to work pretty well.  I tested this against:
    # * Morgan, D - Dane D Morgan - Engineering Physics
    # * Morgan, D - David Morgan  - History Department
    #
    # The two faculty really separate between Collaborators and Keywords

    # @TODO:
    # 1. Crontask / Asynchtask to periodically adjust scores

    person_scoring_hash ||= self.person.scoring_hash
    work_scoring_hash = self.work.scoring_hash

    if person_scoring_hash and work_scoring_hash
      year_score = calculate_year_score(person_scoring_hash, work_scoring_hash)
      publication_score = calculate_publication_score(person_scoring_hash, work_scoring_hash)
      collaborator_score = calculate_collaborator_score(person_scoring_hash, work_scoring_hash)
      keyword_score = calculate_keyword_score(person_scoring_hash, work_scoring_hash)
      self.score = (year_score + publication_score + collaborator_score + keyword_score)
    else
      self.score = 0
    end
  end

  def calculate_keyword_score(person_scoring_hash, work_scoring_hash)
    calculate_inclusion_score(person_scoring_hash[:keyword_ids], work_scoring_hash[:keyword_ids], 25)
  end

  def calculate_collaborator_score(person_scoring_hash, work_scoring_hash)
    calculate_inclusion_score(person_scoring_hash[:collaborator_ids], work_scoring_hash[:collaborator_ids], 25)
  end

  #return 0 if the possible ids are empty, otherwise max_score * the fraction of possible_ids in known_ids
  def calculate_inclusion_score(known_ids, possible_ids, max_score)
    return 0 if possible_ids.empty?
    known_ids = known_ids.to_set
    matches = possible_ids.select do |id|
      known_ids.include?(id)
    end
    return ((max_score / possible_ids.size) * matches.size)
  end

  def calculate_publication_score(person_scoring_hash, work_scoring_hash)
    return 25 if person_scoring_hash[:publication_ids].include?(work_scoring_hash[:publication_id])
    return 0
  end

  def calculate_year_score(person_scoring_hash, work_scoring_hash)
    work_year = work_scoring_hash[:year]
    years_array = person_scoring_hash[:years].compact.sort
    return 0 if years_array.empty?
    year_range = Range.new(years_array.first, years_array.last)
    return (year_range.include?(work_year) ? 25 : 0)
  end

  def calculate_initial_score
    calculate_score
    save
  end

  # Get a count of other unverified contributorships for current Work
  def candidates
    Contributorship.unverified.for_work(self.work_id).size
  end

  # Get a count of possible Person matches to contributorships for current Work
  def possibilities
    logger.debug("\n=== Possibilities ===\n")
    Contributorship.for_work(self.work_id).inject(0) do |acc, c|
      acc + self.work.name_strings.where(:name => c.pen_name.name_string.name).count
    end
  end

  def refresh_contributorships
    # After save method
    # If verified.size == possibilities.size
    # - Loop through competing Contributorships
    # - Set Contributorship.hide = true
    return if self.skip_refresh_contributorships
    if Contributorship.verified.for_work(self.work_id).size == self.possibilities
      logger.debug("\n=== Refresh contributorships ===\n")
      refresh = Contributorship.for_work(self.work).unverified.where('id <> ?', self.id)
      #This previously used save_without_callbacks
      #In this case there is a possibility that removing it will cause an infinite recursion - I'm not sure
      #I understand it well enough to know.
      #If it does, we can add a marker attribute to the object to conditionally skip the after save callback
      #like I've done with some of the others. Set it on each r here before saving and then we ought to
      #be all right.
      #If not, remove this comment and all's well.
      refresh.each do |r|
        r.hide = true
        r.skip_refresh_contributorships = true
        r.save
      end
    end

    # Update Person's scoring hash
    logger.debug("\n=== Updating scoring hash ===\n")
    self.person.update_scoring_hash

    # Update Solr!
    logger.debug("\n=== Reindexing solr for work ===\n")
    self.work.delay.update_solr
    #Index.update_solr(self.work)

  end
end