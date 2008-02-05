class CitationAuthorString   < ActiveRecord::Base
  belongs_to :author_string
  belongs_to :citation
  
  validates_presence_of :author_string_id, :citation_id
  validates_uniqueness_of :citation_id, :scope => :author_string_id
  
  class << self
    def create_batch!(author_string_id, citation_data)
      cites = Citation.import_batch!(citation_data)
      create_batch_from_citations!(author_string_id, cites)
      return cites
    end
  
    def create_batch_from_citations!(author_string, citations)
      return if not citations.respond_to? :each
      citations.each do |c|
        CitationAuthorString.create(:author_string_id => author_string.id, :citation_id => c.id )
      end
    end
  end
end
