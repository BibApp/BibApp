# Filters added to this controller apply to all controllers in the application.
# Likewise, all the methods added will be available for all controllers.

class ApplicationController < ActionController::Base
  helper :all # include all helpers, all the time

  # Include AuthenticationSystem so all controllers support authentication
  include AuthenticatedSystem

  # See ActionController::RequestForgeryProtection for details
  protect_from_forgery

  # Find the @cart variable, used to display "add" or "remove" links for saved Works
  before_filter :find_cart
  
  # Adds a work.id to the session[:cart] array
  def add_to_cart
    @cart = find_cart
    work = Work.find(params[:id])
    @cart.add_work(work)
    redirect_to :back
  end
  
  def add_many_to_cart
    @cart = find_cart
    
    works = Index.fetch_all_ids(params[:query],params[:facets],params[:sort],params[:rows])
    
    works.each do |work|
      work = Work.find(work)
      @cart.add_work(work)
    end
    
    redirect_to :back
  end

  # Removes a work.id to the session[:cart] array  
  def remove_from_cart
    @cart = find_cart
    @cart.remove_work(params[:id].to_i)
    redirect_to :back
  end

  # Sets the session[:cart] array to nil    
  def delete_cart
    session[:cart] = nil
    redirect_to cart_path
  end
  
  private
  
  # Loads the current session cart, or starts a new cart  
  def find_cart
    @cart = session[:cart] ||= Cart.new
  end

end