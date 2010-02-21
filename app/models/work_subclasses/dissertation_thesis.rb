class DissertationThesis < Work
  validates_presence_of :title_primary

  class << self
    def roles
      ['Author', 'Advisor', 'Committee Chair', 'Committee Member', 'Director of Research']
    end

    def creator_role
      'Author'
    end

    def contributor_role
      'Committee Member'
    end
  end

end