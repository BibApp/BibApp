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
    @feed = Feed.find(authorship[:feed_id])

    if params[:commit] == "Save it!"
      # Citation was good, save it
      citations = authorship[:ris]
      cites = Authorship.create_batch!(@person, citations)
      @feed.update_attributes(:feed_state_id => 2)
    elsif params[:commit] == "This is bogus!"
      # Citation was wrong, mark it was bad
      @feed.update_attributes(:feed_state_id => 3)
    end
    # Return to admin/feeds to continue collecting
    redirect_to(:controller => "admin", :action => "feeds")
  end
end
