class ConferenceProceedingWhole < Work
   validates_presence_of :title_primary

  class << self
    def roles
      ['Editor']
    end
  end

end
