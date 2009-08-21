# Filters added to this controller apply to all controllers in the application.
# Likewise, all the methods added will be available for all controllers.

class ApplicationController < ActionController::Base
  helper :all # include all helpers, all the time

  # Include AuthenticationSystem so all controllers support authentication
  include AuthenticatedSystem

  # See ActionController::RequestForgeryProtection for details
  protect_from_forgery

  # Find the @saved variable, used to display "add" or "remove" links for saved Works
  before_filter :find_saved
  
  # Adds a work.id to the session[:saved] array
  def add_to_saved
    @saved = find_saved
    work = Work.find(params[:id])
    @saved.add_work(work)
    redirect_to :back
  end
  
  def add_many_to_saved
    @saved = find_saved
    
    works = Index.fetch_all_ids(params[:query],params[:facets],params[:sort],params[:rows])
    
    works.each do |work|
      work = Work.find(work)
      @saved.add_work(work)
    end
    
    redirect_to :back
  end

  # Removes a work.id to the session[:saved] array  
  def remove_from_saved
    @saved = find_saved
    @saved.remove_work(params[:id].to_i)
    redirect_to :back
  end

  # Sets the session[:saved] array to nil    
  def delete_saved
    session[:saved] = nil
    redirect_to saved_path
  end
  
  private
  
  # Loads the current session saved, or starts a new saved  
  def find_saved
    @saved = session[:saved] ||= Saved.new
  end

end