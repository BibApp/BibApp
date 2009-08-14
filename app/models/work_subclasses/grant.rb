class Grant < Work
  validates_presence_of :title_primary

  class << self
    def roles
      ['Principal Investigator', 'Co-Principal Investigator']
    end
  end

end