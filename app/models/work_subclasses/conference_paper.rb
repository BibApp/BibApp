class ConferencePaper < Work
  validates_presence_of :title_primary

  class << self
    def roles
      ['Author', 'Editor']
    end
  end

end