class AdminController < ApplicationController
  
  make_resourceful do
    build :all
  end
  
  #Find citations which are marked "Ready to Archive"
  def archive
    #@TODO: right now just listing 10 citations...this should be
    # more of a faceted view that allows you to find citations to archive next
    @citations = Citation.find(:all, 
      :conditions => ["citation_archive_state_id = ? and citation_state_id = ?", 2, 3], 
      :limit => 10)
  end
  
end
