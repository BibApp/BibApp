class Authorship   < ActiveRecord::Base
  belongs_to :person
  belongs_to :citation
  
  validates_presence_of :person_id, :citation_id
  validates_uniqueness_of :citation_id, :scope => :person_id
  
  class << self
    def create_batch!(person, citation_data)
      cites = Citation.import_batch!(citation_data)
      create_batch_from_citations!(person, cites)
      return cites
    end
  
    def create_batch_from_citations!(person, citations)
      return if not citations.respond_to? :each
      citations.each do |c|
        Authorship.create(:person_id => person.id, :citation_id => c.id )
      end
    end
  end
end
