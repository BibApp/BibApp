class Authorship   < ActiveRecord::Base
  belongs_to :person
  belongs_to :citation
  belongs_to :pen_name
  
  validates_presence_of :person_id, :citation_id, :pen_name_id
  validates_uniqueness_of :citation_id, :scope => :person_id
  
  before_validation_on_create :set_initial_states
  after_create :calculate_score

  def calculate_score
    # Build the calcuated "score", a rough guess at who has written a citation
    #
    # Field           Value   Scoring Algorithm
    # ---------------------------------------------
    # Yearspan        25      If matches = 25 pts
    # Publication     25      If matches = 25 pts
    # Collaborators   25      (25/total) * matching
    # Keywords        25      (25/total) * matching
    
    # @TODO:
    # Done: Hash of validated person field values
         
    # All scores begin at zero!
    logger.debug("\nPerson: #{self.person.first_last}")
    
    scoring_hash = self.person.scoring_hash
    
    # Add year value if present
    year_score = 0
    year_score = 25 if scoring_hash[:years].include?(self.citation.year)
          
    # Add publication value if present
    publication_score = 0
    publication_score = 25 if scoring_hash[:publication_ids].include?(self.citation.publication.id)
    
    # Add collaborators value if present
    col_poss = self.citation.name_strings.size
    col_matches = 0

    self.citation.name_strings.each do |ns|
      col_matches = (col_matches + 1) if scoring_hash[:collaborator_ids].include?(ns.id)
    end
    
    collaborator_score = 0
    collaborator_score = ((25/col_poss)*col_matches)
    
    # Add keywords value if present
    key_poss = self.citation.keywords.size
    key_matches = 0
    
    self.citation.keywords.each do |k|
      key_matches = (key_matches + 1) if scoring_hash[:keyword_ids].include?(k.id)
    end
    
    keyword_score = 0
    keyword_score = ((25/key_poss)*key_matches)
    
    # Debugging the scoring algoritm
    logger.debug("\n\n========================================")
    logger.debug("Year: #{year_score}")
    logger.debug("Publication: #{publication_score}")
    logger.debug("Collaborators: (25/#{col_poss}) * #{col_matches} = #{collaborator_score}")
    logger.debug("Keywords: (25/#{key_poss}) * #{key_matches} = #{keyword_score}")
    logger.debug("*Final Score:* #{(year_score + publication_score + collaborator_score + keyword_score)}")
    logger.debug("========================================\n\n")

    self.score = (year_score + publication_score + collaborator_score + keyword_score)
    self.save
  end
  
  # All Citations begin unverified
  def set_initial_states
    self.authorship_state_id = 1
    self.score = 0
  end
end