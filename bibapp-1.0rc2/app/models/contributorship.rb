class Contributorship   < ActiveRecord::Base
 
  #### Associations ####
  belongs_to :person
  belongs_to :work
  belongs_to :pen_name
  
  #### Named Scopes ####
  #Various Contributorship statuses
  named_scope :unverified, :conditions => ["contributorships.contributorship_state_id = ?", 1]
  named_scope :verified, :conditions => ["contributorships.contributorship_state_id = ?", 2]
  named_scope :denied, :conditions => ["contributorships.contributorship_state_id = ?", 3]
  # TODO: For now we don't want editors showing up as contributors
  #   although in the future we might want them to show up for whole
  #   conference preceedings, entire books, et cetera
  named_scope :visible, :conditions => ["contributorships.hide = ? and contributorships.role = ?", false, "Author"]
  #By default, show all verified, visible contributorships
  named_scope :to_show, :conditions => ["contributorships.hide = ? and contributorships.contributorship_state_id = ?", false, 2]
  #All contributorships for a specified work
  named_scope :for_work, lambda { |work_id| {:conditions => ["contributorships.work_id = ?", work_id]}}
  
  #### Validations ####
  validates_presence_of :person_id, :work_id, :pen_name_id
  validates_uniqueness_of :work_id, :scope => :person_id
  
  #### Callbacks ####
  before_validation_on_create :set_initial_states
  after_create :calculate_score
  
  def after_save
    # Delayed Job - Remove false positives from other PenName claimants
    logger.debug("\n=== REFRESHING ===\n")
    self.send_later(:refresh_contributorships)
    #self.refresh_contributorships

# I'm moving this block into :refresh_contributorships
# so that it will be done later. - bill 1/26/10
#    if self.contributorship_state_id_changed?
#      # Update Person's scoring hash
#      self.person.update_scoring_hash
#
#      # Update Solr!
#      Index.update_solr(self.work)
#    end
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
    self.contributorship_state_id = 1
    self.hide = false
    self.score = 0
  end
  
  def unverified?
    return true if self.contributorship_state_id == 1
  end
  
  def unverify_contributorship
    self.contributorship_state_id = 1
    # if the contributorship is going from denied -> unverified
    # we need it to be unhidden
    self.hide = false
  end
  
  def verified?
    return true if self.contributorship_state_id == 2
  end
  
  def verify_contributorship
    self.contributorship_state_id = 2
    # if the contributorship is going from denied -> verified
    # we need it to be unhidden
    self.hide = false
    self.save
  end
  
  def denied?
    return true if self.contributorship_state_id == 3
  end
  
  def deny_contributorship
    # Denying a Contributorship requires following
    # 1. Set state to "Denied"
    # 2. Set hide to "true"
    # 3. Set score to "zero"
    self.contributorship_state_id = 3
    self.hide = true
    self.score = 0
  end
  
  def visible?
    return true if self.hide == false
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
      
      unless person_sh[:years].empty?
        person_sh[:years].sort.first.upto(person_sh[:years].sort.last){|y| years << y }
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
    self.save_without_callbacks
  end
 
  # Get a count of other unverified contributorships for current Work
  def candidates
    candidates = Contributorship.unverified.for_work(self.work_id).size
  end
  
   # Get a count of possible Person matches to contributorships for current Work
  def possibilities
    count = Array.new
    # I don't think this is working as intended
    #possibilities = self.work.name_strings.each{|ns| count << ns if ns.name == self.pen_name.name_string.name }

    Contributorship.find_all_by_work_id(self.work_id).each{ |c|
      possibilities = self.work.name_strings.each{|ns| count << ns if ns.name == c.pen_name.name_string.name }
    }

    return count.size
  end

  def save_without_callbacks
    create_or_update_without_callbacks
  end
  
  def refresh_contributorships
    # After save method
    # If verified.size == possibilities.size
    # - Loop through competing Contributorships
    # - Set Contributorship.hide = true
    
    if Contributorship.verified.for_work(self.work_id).size == self.possibilities
      refresh = Contributorship.find(
        :all, 
        :conditions => [
          "work_id = ? and contributorship_state_id = ? and id <> ?", 
          self.work_id,
          1,
          self.id
        ]
      )
      
      refresh.each do |r|
        r.hide = true
        r.save_without_callbacks
      end
    end
    
    # Update Person's scoring hash
    self.person.update_scoring_hash

    # Update Solr!
    Index.update_solr(self.work)

  end
end