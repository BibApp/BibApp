class JournalWhole < Work
   validates_presence_of :title_primary

  class << self
    def roles
      ['Editor', 'Managing Editor', 'Editorial Board Member']
    end
  end

end
