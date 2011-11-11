class Exhibition < Work

  def self.roles
    ['Artist', 'Curator']
  end

  def self.creator_role
    'Artist'
  end

  def self.contributor_role
    'Curator'
  end

end
