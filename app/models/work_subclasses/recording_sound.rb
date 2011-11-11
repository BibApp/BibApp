class RecordingSound < Work

  def self.roles
    ['Musician', 'Performer', 'Interviewer', 'Interviewee', 'Musical Ensemble']
  end

  def self.creator_role
    'Performer'
  end

  def self.contributor_role
    'Performer'
  end

  def type_uri
    "http://purl.org/dc/dcmitype/Sound" #DCMI Type
  end
end
