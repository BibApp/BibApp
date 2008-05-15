# Citation's Archive Status
class CitationArchiveState < ActiveRecord::Base
  #there are many citations in the same state
  has_many :citations
end