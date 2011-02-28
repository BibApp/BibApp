class JournalWhole < Work
  validates_presence_of :title_primary

  def self.roles
    ['Editor', 'Managing Editor', 'Editorial Board Member']
  end

  def self.creator_role
    'Editor'
  end

  def self.contributor_role
    'Editorial Board Member'
  end

end
