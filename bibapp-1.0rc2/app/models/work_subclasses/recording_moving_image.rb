class RecordingMovingImage < Work
   validates_presence_of :title_primary

  class << self
    def roles
      ['Director', 'Producer', 'Actor', 'Performer']
    end

    def creator_role
      'Director'
    end

    def contributor_role
      'Performer'
    end
  end

end
