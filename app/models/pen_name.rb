class PenName < ActiveRecord::Base
  belongs_to :name_string
  belongs_to :person
  has_many :authorships
  
  validates_presence_of :name_string_id, :person_id
  
  # PenNames provide the logic for creating and destroying Authorships
  # PenName lifecycle needs create or destroy associated Authorships
  # @TODO: move these callbacks to a pen_name_observer
  #
  # after_save
  #
  # 1. Person has a new PenName
  # * Create a Authorship row for each unique Citation associated with PenName
  # * Set Authorship.score to calculated (options: calculated (0), verified (1), wrong/incorrect (2))
  #
  # 2. More than one Person claims same PenName
  # * Add Authorship row, as described above
  # * Maybe use the authorship.hide column? But it doesn't feel right today...
  # * @TODO Create a "authorships/admin?view=duplicate_claims"
  #
  # before_destroy
  #
  # 1. Remove related Authorship rows
  
  after_save :set_authorships
  before_destroy :remove_authorships
  
    
  def set_authorships
    self.name_string.citations.each do |citation|
      if citation.citation_state_id == 3
        as = Authorship.find_or_create_by_citation_id_and_person_id_and_pen_name_id(citation.id, self.person_id, self.id)
        as.update_attributes(:score => 0)
      end
    end
  end
  
  def remove_authorships
    authorships = Authorship.find(:all, :conditions => ["pen_name_id = ? and person_id = ?", self.id, self.person_id])
    authorships.each{|authorship| authorship.destroy}
  end
end
