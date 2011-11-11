class Performance < Work

  def self.roles
    ['Director', 'Conductor', 'Actor', 'Musician', 'Dancer', 'Costume Designer', 'Lighting Designer', 'Choreographer', 'Composer', 'Producer', 'Orchestra', 'Band', 'Choir', 'Other']
  end

  def self.creator_role
    'Director'
  end

  def self.contributor_role
    'Musician'
  end

end
