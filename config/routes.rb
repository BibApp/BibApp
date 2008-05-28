ActionController::Routing::Routes.draw do |map|
  
  # The priority is based upon order of creation: first created -> highest priority.

  # Sample of regular route:
  #   map.connect 'products/:id', :controller => 'catalog', :action => 'view'
  # Keep in mind you can assign values other than :controller and :action

  # Sample of named route:
  #   map.purchase 'products/:id/purchase', :controller => 'catalog', :action => 'purchase'
  # This route can be invoked with purchase_url(:id => product.id)

  # Sample resource route (maps HTTP verbs to controller actions automatically):
  #   map.resources :products

  # Sample resource route with options:
  #   map.resources :products, :member => { :short => :get, :toggle => :post }, :collection => { :sold => :get }

  # Sample resource route with sub-resources:
  #   map.resources :products, :has_many => [ :comments, :sales ], :has_one => :seller

  # Sample resource route within a namespace:
  #   map.namespace :admin do |admin|
  #     # Directs /admin/products/* to Admin::ProductsController (app/controllers/admin/products_controller.rb)
  #     admin.resources :products
  #   end

  # You can have the root of your site routed with map.root -- just remember to delete public/index.html.
  # map.root :controller => "welcome"

  # See how all your routes lay out with "rake routes"

  #Auto-Complete Routes for Web-Based Citation entry
  map.resources :citations, 
                :collection => {:auto_complete_for_author_string => :get,
                        :auto_complete_for_editor_string => :get,
                				:auto_complete_for_keyword_name => :get,
								        :auto_complete_for_publication_name => :get,
                        :auto_complete_for_publisher_name => :get}
  
 map.resources :memberships, 
                :collection => {:auto_complete_for_group_name => :get}
                
 map.resources :groups, 
                :collection => {:auto_complete_for_group_name => :get}
  
  # Install the default routes as the lowest priority.
    
  map.resources :name_strings,
    :groups,
    :memberships,
    :pen_names,
    :keywords,
    :keywordings,
    :attachments
  
  # Make URLs like /people/1/attachments/2 for Person Images
  map.resources :people do |p|
    p.resources :attachments
  end
  
  # Make URLs like /citation/2/attachments/4 for Citation Content Files
  map.resources :citations do |c|
    c.resources :attachments
  end
  
  map.resources :contributorships, :collection => { :admin => :get, :archivable => :get }, :member => { :verify => :put, :deny => :put } 
    
  map.resources :publishers,    :collection => { :authorities => :get, :update_multiple => :put }
  map.resources :publications,  :collection => { :authorities => :get, :update_multiple => :put }
  
  map.search 'search', :controller => 'search', :action => 'index'
  
  map.connect "/",
    :controller => 'citations',
    :action => 'index'
    
  map.connect ':controller/:action/:id'
  map.connect ':controller/:action/:id.:format'
  
  
end
