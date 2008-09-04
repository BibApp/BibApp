# Work's Archive Status
class WorkArchiveState < ActiveRecord::Base
  #there are many Works in the same state
  has_many :works
  
  
  #return the "initial" state
  def self.initial
    WorkArchiveState.find(1)
  end
  
  #return the "ready to archive" state
  def self.ready_to_archive
    WorkArchiveState.find(2)
  end
  
  #check if this work is in "ready to archive" state
  def self.ready_to_archive?(work)
    return (work.work_archive_state == WorkArchiveState.ready_to_archive)
  end
  
  
  #return the "archived" state
  def self.archived
    WorkArchiveState.find(7)
  end
  
  #check if this work is in "archived" state
  def self.archived?(work)
    return (work.work_archive_state == WorkArchiveState.archived)
  end
  
end