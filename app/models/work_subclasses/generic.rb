class Generic < Work
  validates_presence_of :title_primary

  class << self
    def roles
      ['Creator', 'Contributor']
    end

    def creator_role
      'Creator'
    end

    def contributor_role
      'Contributor'
    end
  end

end