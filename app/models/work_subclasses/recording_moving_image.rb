class RecordingMovingImage < Work

  def self.roles
    ['Director', 'Producer', 'Actor', 'Performer']
  end

  def self.creator_role
    'Director'
  end

  def self.contributor_role
    'Performer'
  end

  def type_uri
    "http://purl.org/dc/dcmitype/MovingImage"  #DCMI Type
  end

end
