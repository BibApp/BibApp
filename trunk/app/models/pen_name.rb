class PenName < ActiveRecord::Base
  belongs_to :name_string
  belongs_to :person
  has_many :contributorships
  
  validates_presence_of :name_string_id, :person_id
  
  # PenNames provide the logic for creating and destroying Contributorships
  # PenName lifecycle needs create or destroy associated Contributorships
  # @TODO: move these callbacks to a pen_name_observer
  #
  # after_save
  #
  # 1. Person has a new PenName
  # * Create a Contributorship row for each unique Citation associated with PenName
  # * Set Contributorship.score to calculated (options: calculated (0), verified (1), denied (2))
  #
  # 2. More than one Person claims same PenName
  # * Add Contributorship row, as described above
  # * Maybe use the contributorship.hide column? But it doesn't feel right today...
  # * @TODO Create a "contributorships/admin?view=duplicate_claims"
  #
  # before_destroy
  #
  # 1. Remove related Contributorship rows
  
  after_save :set_contributorships
  before_destroy :remove_contributorships
    
  def set_contributorships
    self.name_string.citation_name_strings.each do |cns|
      if cns.citation.citation_state_id == 3
        cs = Contributorship.find_or_create_by_citation_id_and_person_id_and_pen_name_id_and_role(
            cns.citation.id, 
            self.person_id, 
            self.id,
            cns.role
          )
      end
    end
  end
  
  def remove_contributorships
    contributorships = Contributorship.find(
        :all, 
        :conditions => ["pen_name_id = ? and person_id = ?", self.id, self.person_id]
      )
    contributorships.each{|c| c.destroy}
  end
end
