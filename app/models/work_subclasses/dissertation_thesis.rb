class DissertationThesis < Work
  validates_presence_of :title_primary

  class << self
    def roles
      ['Author', 'Advisor', 'Committee Chair', 'Committee Member', 'Director of Research']
    end
  end

end