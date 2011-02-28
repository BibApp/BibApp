class PresentationLecture < Work
  validates_presence_of :title_primary

  def self.roles
    ['Presenter']
  end

  def self.creator_role
    'Presenter'
  end

  def self.contributor_role
    'Presenter'
  end

end
