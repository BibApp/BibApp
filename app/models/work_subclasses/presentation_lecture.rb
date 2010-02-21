class PresentationLecture < Work
   validates_presence_of :title_primary

  class << self
    def roles
      ['Presenter']
    end

    def creator_role
      'Presenter'
    end

    def contributor_role
      'Presenter'
    end
  end

end
