class RecordingSound < Work
   validates_presence_of :title_primary

  class << self
    def roles
      ['Musician', 'Performer', 'Interviewer', 'Interviewee', 'Musical Ensemble']
    end

    def creator_role
      'Performer'
    end

    def contributor_role
      'Performer'
    end
  end

end
