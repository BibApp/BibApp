class RecordingSound < Work
   validates_presence_of :title_primary

  class << self
    def roles
      ['Musician', 'Performer', 'Interviewer', 'Interviewee', 'Musical Ensemble']
    end
  end

end
