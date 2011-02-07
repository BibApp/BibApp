ActionController::Routing::Routes.draw do |map|

  map.resources :works,
      :collection => {:auto_complete_for_author_string => :get,
          :auto_complete_for_editor_string => :get,
          :auto_complete_for_keyword_name => :get,
          :auto_complete_for_publication_name => :get,
          :auto_complete_for_publisher_name => :get,
          :auto_complete_for_tag_name => :get,
          :review_batch => :get,
          :destroy_multiple => :delete},
      :member => {:merge_duplicates => :get} do |c|
    # Make URLs like /work/2/attachments/4 for Work Content Files
    c.resources :attachments
  end

  #####
  # Person routes
  #####
  map.resources :people do |p|
    # Make URLs like /people/1/attachments/2 for Person Images
    p.resources :attachments
    # Make URLs like /people/1/works (and allow adding Works to People)
    p.resources :works
    # Make URLs like /people/1/groups
    p.resources :groups
    # Make URLs like /people/1/pen_names
    p.resources :pen_names
    # Make URLs like /people/1/memberships
    p.resources :memberships
    # Make URLs like /people/1/roles/3 for user roles on a specific Person
    p.resources :roles, :collection => {:new_admin => :get, :new_editor => :get}
    # Make URLs like /people/1/keywords/
    p.resources :keywords, :collection => {:timeline => :get}
  end

  #####
  # Group routes
  ##### 
  # Add Auto-Complete routes for adding new groups
  map.resources :groups,
      :collection => {:auto_complete_for_group_name => :get,
          :hidden => :get} do |g|
    # Make URLs like /group/1/works/4
    g.resources :works
    # Make URLs like /group/1/people/4
    g.resources :people
    # Make URLs like /group/1/roles/3 for roles on a specific Group
    g.resources :roles, :collection => {:new_admin => :get, :new_editor => :get}
    # Make URLs like /group/1/keywords/
    g.resources :keywords, :collection => {:timeline => :get}
  end

  #####
  # Membership routes
  #####
  # Add Auto-Complete routes
  map.resources :memberships,
      :collection => {:auto_complete_for_group_name => :get,
          :create_multiple => :put
      }

  #####
  # Contributorship routes
  #####
  map.resources :contributorships,
      :collection => {:admin => :get,
          :archivable => :get,
          :verify_multiple => :put,
          :unverify_multiple => :put,
          :deny_multiple => :put},
      :member => {:verify => :put, :deny => :put}

  #####
  # Publisher routes
  #####   
  map.resources :publishers, :collection => {:authorities => :get,
      :update_multiple => :put,
      :add_to_box => :get,
      :remove_from_box => :get}


  #####
  # Publication routes
  #####
  map.resources :publications, :collection => {:authorities => :get,
      :update_multiple => :put,
      :add_to_box => :get,
      :remove_from_box => :get}

  ####
  # User routes
  ####
  # Make URLs like /user/1/password/edit for Users managing their passwords
  map.resources :users, :has_one => [:password] do |u|
    u.resources :imports
  end
  ####
  # Import routes
  ####
  map.resources :imports, :has_one => [:user] do |i|
    i.resources :attachments
  end

  ####
  # Search route
  ####
  map.search 'search', :controller => 'search', :action => 'index'
  map.advanced_search 'search/advanced', :controller => 'search', :action => 'advanced'
  ####
  # Saved routes
  ####
  map.saved '/saved',
      :controller => 'sessions',
      :action => 'saved'
  map.delete_saved '/sessions/delete_saved',
      :controller => 'sessions',
      :action => 'delete_saved'
  map.add_many_to_saved '/sessions/add_many_to_saved',
      :controller => 'sessions',
      :action => 'add_many_to_saved'

  ####
  # Authentication routes
  ####
  # Make easier routes for authentication (via restful_authentication)
  map.signup '/signup',
      :controller => 'users',
      :action => 'new'
  map.login '/login',
      :controller => 'sessions',
      :action => 'new'
  map.logout '/logout',
      :controller => 'sessions',
      :action => 'destroy'
  map.activate '/activate/:activation_code',
      :controller => 'users',
      :action => 'activate'

  ####
  # DEFAULT ROUTES 
  ####
  # Install the default routes as the lowest priority.
  map.resources :name_strings,
      :memberships,
      :pen_names,
      :keywords,
      :keywordings,
      :sessions,
      :passwords,
      :attachments

  # Default homepage to works index action
  map.root :controller => 'works',
      :action => 'index'

  map.connect "citations",
      :controller => 'works',
      :action => 'index'

  map.connect ':controller/:action/:id'
  map.connect ':controller/:action/:id.:format'

end
