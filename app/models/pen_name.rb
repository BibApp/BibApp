class PenName < ActiveRecord::Base
  belongs_to :author_string
  belongs_to :person
  has_many :authorships
  
  validates_presence_of :author_string_id, :person_id
  
  # @TODO: PenNames provide the logic for setting Authorships
  # after_save
  #
  # 1. Person has a new PenName
  # * Insert a Authorship row for each Citation associated with PenName
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
    self.author_string.citations.each do |citation|
      as = Authorship.find_or_create_by_citation_id_and_person_id_and_pen_name_id(citation.id, self.person_id, self.id)
      as.update_attributes(:score => 0)
    end
  end
  
  def remove_authorships
    authorships = Authorship.find(:all, :conditions => ["pen_name_id = ? and person_id = ?", self.id, self.person_id])
    authorships.each{|authorship| authorship.destroy}
  end
end
