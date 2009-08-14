class PresentationLecture < Work
   validates_presence_of :title_primary

  class << self
    def roles
      ['Presenter']
    end
  end

end
