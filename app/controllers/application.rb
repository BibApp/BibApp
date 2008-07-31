# Filters added to this controller apply to all controllers in the application.
# Likewise, all the methods added will be available for all controllers.

class ApplicationController < ActionController::Base
  helper :all # include all helpers, all the time

  # Include AuthenticationSystem so all controllers support authentication
  include AuthenticatedSystem

  # See ActionController::RequestForgeryProtection for details
  # Uncomment the :secret if you're not using the cookie session store
  protect_from_forgery :secret => '6ef4f4bba39aae6ef1a1da02e1ace6d8'
  
  # Adds a citation.id to the session[:cart] array
  def add_to_cart
    @cart = find_cart
    citation = Citation.find(params[:id])
    @cart.add_citation(citation)
    redirect_to :back
  end

  # Removes a citation.id to the session[:cart] array  
  def remove_from_cart
    @cart = find_cart
    @cart.remove_citation(params[:id].to_i)
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
    session[:cart] ||= Cart.new
  end

end