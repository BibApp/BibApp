class ConferenceProceedingWhole < Work
   validates_presence_of :title_primary

  class << self
    def roles
      ['Editor']
    end

    def creator_role
      'Editor'
    end

    def contributor_role
      'Editor'
    end
  end

end
