class Composition < Work
  validates_presence_of :title_primary

  def self.roles
    ['Composer']
  end

  def self.creator_role
    'Composer'
  end

  def self.contributor_role
    'Composer'
  end

end
