class JournalWhole < Work
   validates_presence_of :title_primary

  class << self
    def roles
      ['Editor', 'Managing Editor', 'Editorial Board Member']
    end

    def creator_role
      'Editor'
    end

    def contributor_role
      'Editorial Board Member'
    end
  end

end
