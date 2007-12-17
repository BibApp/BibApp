class Authorship < ActiveRecord::Base
  belongs_to :author
  belongs_to :citation
  
  validates_presence_of :author_id, :citation_id
  validates_uniqueness_of :citation_id, :scope => :author_id
  
  class << self
    def create_batch!(author, citation_data)
      cites = Citation.import_batch!(citation_data)
      create_batch_from_citations!(author, cites)
      return cites
    end
  
    def create_batch_from_citations!(author, citations)
      return if not citations.respond_to? :each
      citations.each do |c|
        Authorship.create(:author_id => author.id, :citation_id => c.id )
      end
    end
  end
end
