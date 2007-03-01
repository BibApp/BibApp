ActionController::Routing::Routes.draw do |map|
  # The priority is based upon order of creation: first created -> highest priority.
  
  # Sample of regular route:
  # map.connect 'products/:id', :controller => 'catalog', :action => 'view'
  # Keep in mind you can assign values other than :controller and :action
  
  
  # Sample of named route:
  # map.purchase 'products/:id/purchase', :controller => 'catalog', :action => 'purchase'
  # This route can be invoked with purchase_url(:id => product.id)

  # You can have the root of your site routed by hooking up '' 
  # -- just remember to delete public/index.html.
  # map.connect '', :controller => "welcome"
  
  map.connect "/people/ldap_results",
    :controller => "people",
    :action => "ldap_results"
  map.connect "/citations/list",
    :controller => "citations",
    :action => "list"

  map.resources :citations, :memberships, :people, :groups, :publishers

  # Install the default route as the lowest priority.

  map.connect "/",
    :controller => 'groups',
    :action => 'index'
  map.connect "/account/login",
    :controller => 'account',
    :action => 'login'
  map.connect "/about",
    :controller => 'about',
    :action => 'index'
  map.connect "/search",
    :controller => 'search',
    :action => 'index'
  map.keyword_page '/keywords/:url_abbrev',
    :controller => 'keywords',
    :action => 'view_timeline',
    :url_abbrev => 'url_abbrev'
  map.connect ':controller/:action/:id'
end
