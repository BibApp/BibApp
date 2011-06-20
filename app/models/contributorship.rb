class Contributorship < ActiveRecord::Base

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
  #   conference preceedings, entire books, et cetera
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
  end

  def visible?
    self.hide == false
  end


  ########## Methods ##########  
  def calculate_score

    # Build the calcuated Contributorship.score attribute--a rough
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
    # 1. Stop reloading self.person.scoring_hash for each Work (super slow, 100s of queries)
    # 2. Crontask / Asynchtask to periodically adjust scores

    person_sh = self.person.scoring_hash
    work_sh = self.work.scoring_hash

    if person_sh && !person_sh.nil? && !work_sh.nil?
      # Years
      year_score = 0
      years = Array.new
      # Build full array of publishing years


      logger.debug("Year: #{work_sh[:year]}")


      years_array = person_sh[:years].compact.sort
      unless years_array.empty?
        years_array.first.upto(years_array.last) { |y| years << y }
        logger.debug("Array: #{years.inspect}")
        year_score = 25 if years.include?(work_sh[:year])
      end

      # Publications
      publication_score = 0
      publication_score = 25 if person_sh[:publication_ids].include?(work_sh[:publication_id])

      # Collaborators
      col_poss = work_sh[:collaborator_ids].size
      col_matches = 0

      work_sh[:collaborator_ids].each do |ns|
        col_matches = (col_matches + 1) if person_sh[:collaborator_ids].include?(ns)
      end

      collaborator_score = 0
      collaborator_score = ((25/col_poss)*col_matches) if col_poss != 0

      # Keywords
      key_poss = work_sh[:keyword_ids].size
      key_matches = 0

      work_sh[:keyword_ids].each do |k|
        key_matches = (key_matches + 1) if person_sh[:keyword_ids].include?(k)
      end

      keyword_score = 0
      keyword_score = ((25/key_poss)*key_matches) if key_poss != 0

      # Debugging the scoring algoritm
      logger.debug("\n\n========================================")
      logger.debug("Year: #{year_score}")
      logger.debug("Publication: #{publication_score}")
      logger.debug("Collaborators: (25/#{col_poss}) * #{col_matches} = #{collaborator_score}")
      logger.debug("Keywords: (25/#{key_poss}) * #{key_matches} = #{keyword_score}")
      logger.debug("*Final Score:* #{(year_score + publication_score + collaborator_score + keyword_score)}")
      logger.debug("========================================\n\n")

      self.score = (year_score + publication_score + collaborator_score + keyword_score)
    else
      self.score = 0
    end
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
    Contributorship.for_work(self.work_id).inject(0) do |acc, c|
      acc + self.work.name_strings.where(:name => c.pen_name.name_string.name).count
    end
  end

  def refresh_contributorships
    # After save method
    # If verified.size == possibilities.size
    # - Loop through competing Contributorships
    # - Set Contributorship.hide = true

    if Contributorship.verified.for_work(self.work_id).size == self.possibilities
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
        r.save
      end
    end

    # Update Person's scoring hash
    self.person.update_scoring_hash

    # Update Solr!
    Index.update_solr(self.work)

  end
end