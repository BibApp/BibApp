class Artwork < Work
  validates_presence_of :title_primary

  class << self
    def roles
      ['Artist', 'Curator']
    end

    def creator_role
      'Artist'
    end

    def contributor_role
      'Curator'
    end
  end

end