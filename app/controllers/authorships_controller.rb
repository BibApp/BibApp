class AuthorshipsController < ApplicationController
  
  def create
    @person = Person.find(params[:person_id])
    
    if request.post?
      # Handle the file upload, redirect to the list of this person's citations
      file = Upload.save(@person, params[:upload]) 

      Authorship.create_batch!(@person, file)

      redirect_to(:controller => "people", :action => "show", :id => @person.id)
      
    end
  end
  
  def create_from_ris
    authorship = params[:authorship]
    @person = Person.find(authorship[:person_id])

    # Handle the citations, redirect to the list of this person's citations
    citations = authorship[:ris]
    
    cites = Authorship.create_batch!(@person, citations)
    logger.debug("Cites returns: #{cites}")
    
    @feed = Feed.find(authorship[:feed_id])
    @feed.update_attributes(:feed_state_id => 2)
    redirect_to(:controller => "admin", :action => "feeds")
  end
end
