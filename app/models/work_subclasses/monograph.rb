class Monograph < Work
  validates_presence_of :title_primary

  class << self
    def roles
      ['Author', 'Editor', 'Translator', 'Illustrator']
    end
  end

end