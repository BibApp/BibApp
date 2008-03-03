class CitationNameString   < ActiveRecord::Base
  belongs_to :name_string
  belongs_to :citation
  acts_as_list :scope => :citation_id
  
  validates_presence_of :name_string_id, :citation_id
  validates_uniqueness_of :citation_id, :scope => :name_string_id
  
  class << self
    def create_batch!(name_string_id, citation_data)
      cites = Citation.import_batch!(citation_data)
      create_batch_from_citations!(name_string_id, cites)
      return cites
    end
  
    def create_batch_from_citations!(name_string, citations)
      return if not citations.respond_to? :each
      citations.each do |c|
        CitationNameString.create(:name_string_id => name_string.id, :citation_id => c.id )
      end
    end
  end
end
