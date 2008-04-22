class Contributorship   < ActiveRecord::Base
  belongs_to :person
  belongs_to :citation
  belongs_to :pen_name
  
  validates_presence_of :person_id, :citation_id, :pen_name_id
  validates_uniqueness_of :citation_id, :scope => :person_id
  
  before_validation_on_create :set_initial_states
  after_create :calculate_score
  
  after_save do |contributorship|
    # Remove false positives from other PenName claimants
    contributorship.refresh_contributorships
    
    # Update Solr!
    # * Citations have many People...
    # * But, only if contributorship_state_id == 2 (verified)
    Index.update_solr(contributorship.citation)
  end
  
  after_destroy do |contributorship|
    # Update Solr!
    # * Citations have many People...
    # * But, only if contributorship_state_id == 2 (verified)
    Index.update_solr(contributorship.citation)
  end

  def calculate_score
    
    # Build the calcuated Contributorship.score attribute--a rough
    # guess whether we think the Person has written the Citation
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
    # 1. Stop reloading self.person.scoring_hash for each citation (super slow, 100s of queries)
    # 2. Crontask / Asynchtask to periodically adjust scores
         
    person_sh = self.person.scoring_hash
    citation_sh = self.citation.scoring_hash

    if person_sh && !person_sh.nil?
      # Years
      year_score = 0
      years = Array.new
      # Build full array of publishing years

      logger.debug("Year: #{citation_sh[:year]}")
      
      person_sh[:years].sort.first.upto(person_sh[:years].sort.last){|y| years << y }
      logger.debug("Array: #{years.inspect}")
      year_score = 25 if years.include?(citation_sh[:year])
    
      # Publications
      publication_score = 0
      publication_score = 25 if person_sh[:publication_ids].include?(citation_sh[:publication_id])
    
      # Collaborators
      col_poss = citation_sh[:collaborator_ids].size
      col_matches = 0

      citation_sh[:collaborator_ids].each do |ns|
        col_matches = (col_matches + 1) if person_sh[:collaborator_ids].include?(ns.object_id)
      end
    
      collaborator_score = 0
      collaborator_score = ((25/col_poss)*col_matches) if col_poss != 0
    
      # Keywords
      key_poss = citation_sh[:keyword_ids].size
      key_matches = 0
    
      citation_sh[:keyword_ids].each do |k|
        key_matches = (key_matches + 1) if person_sh[:keyword_ids].include?(k.object_id)
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
  
  def set_initial_states
    # All Contributions start with:
    # * state - "Unverified" 
    # * hide  - 0 (false)
    # * score - 0 (zero)
    self.contributorship_state_id = 1
    self.hide = 0
    self.score = 0
  end

  def candidates
    candidates = Contributorship.count(
      :conditions => ["
        citation_id = ? and contributorship_state_id = ?", 
        self.citation_id,
        1 # caluculated
      ]
    )
  end
  
  def possibilities
    count = Array.new
    possibilities = self.citation.name_strings.each{|ns| count << ns if ns.name == self.pen_name.name_string.name }
    return count.size
  end
  
  def verified
    verified = Contributorship.count(
      :conditions => ["
        citation_id = ? and contributorship_state_id = ?", 
        self.citation_id,
        2 # caluculated
      ]
    )
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
          "citation_id = ? and contributorship_state_id = ? and id <> ?", 
          self.citation_id,
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