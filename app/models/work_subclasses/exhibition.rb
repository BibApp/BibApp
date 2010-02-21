class Exhibition < Work
   validates_presence_of :title_primary

  class << self
    def roles
      ['Artist', 'Curator']
    end

    def creator_role
      'Author'
    end

    def contributor_role
      'Curator'
    end
  end

end
