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
  named_scope :visible, :conditions => ["contributorships.hide = ?", false]
  #By default, show all verified, visible contributorships
  named_scope :to_show, :conditions => ["contributorships.hide = ? and contributorships.contributorship_state_id = ?", false, 2]
  
  #### Validations ####
  validates_presence_of :person_id, :work_id, :pen_name_id
  validates_uniqueness_of :work_id, :scope => :person_id
  
  #### Callbacks ####
  before_validation_on_create :set_initial_states
  after_create :calculate_score
  
  after_save do |contributorship|
    # Remove false positives from other PenName claimants
    logger.debug("\n=== REFRESHING ===\n")
    contributorship.refresh_contributorships
    
    if contributorship.verified?   
      # Update Solr!
      # * Works have many People...
      # * But, only if contributorship_state_id == 2 (verified)
      Index.update_solr(contributorship.work)
    end
  end
  
  ## Note: no 'after_destroy' is necessary here, as PenNameObserver 
  ## takes care of updating Solr before destroying Contributorships
  ## associated with a PenName.

  ##### Contributorship State Methods #####
  def unverified?
    return true if self.contributorship_state_id == 1
  end
  
  def verified?
    return true if self.contributorship_state_id == 2
  end
  
  def denied?
    return true if self.contributorship_state_id == 3
  end
  
  def visible?
    return true if self.contributorships.hide == false
  end
  
  def set_initial_states
    # All Contributions start with:
    # * state - "Unverified" 
    # * hide  - 0 (false)
    # * score - 0 (zero)
    self.contributorship_state_id = 1
    self.hide = false
    self.score = 0
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
      
      
      person_sh[:years].sort.first.upto(person_sh[:years].sort.last){|y| years << y }
      logger.debug("Array: #{years.inspect}")
      year_score = 25 if years.include?(work_sh[:year])

    
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
    self.save
  end
  

  def verify
    
  end
  
  # Get a count of other unverified contributorships for current Work
  def candidates
    candidates = Contributorship.unverified.count(
      :conditions => ["work_id = ?", self.work_id]
    )
  end
  
   # Get a count of possible Person matches to contributorships for current Work
  def possibilities
    count = Array.new
    possibilities = self.work.name_strings.each{|ns| count << ns if ns.name == self.pen_name.name_string.name }
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
    
    if self.verified == self.possibilities
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
  end
end