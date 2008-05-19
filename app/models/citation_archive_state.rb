# Citation's Archive Status
class CitationArchiveState < ActiveRecord::Base
  #there are many citations in the same state
  has_many :citations
  
  
  #return the "initial" state
  def self.initial
    CitationArchiveState.find(1)
  end
  
  #return the "ready to archive" state
  def self.ready_to_archive
    CitationArchiveState.find(2)
  end
  
  #check if this citation is in "ready to archive" state
  def self.ready_to_archive?(citation)
    return (citation.citation_archive_state == CitationArchiveState.ready_to_archive)
  end
  
  
  #return the "archived" state
  def self.archived
    CitationArchiveState.find(7)
  end
  
  #check if this citation is in "archived" state
  def self.archived?(citation)
    return (citation.citation_archive_state == CitationArchiveState.archived)
  end
  
end