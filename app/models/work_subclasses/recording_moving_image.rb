class RecordingMovingImage < Work
   validates_presence_of :title_primary

  class << self
    def roles
      ['Director', 'Producer', 'Actor', 'Performer']
    end
  end

end
