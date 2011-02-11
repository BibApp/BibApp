Bibapp::Application.routes.draw do

  resources :works do
    collection do
      get :auto_complete_for_author_string
      get :auto_complete_for_editor_string
      get :auto_complete_for_keyword_name
      get :auto_complete_for_publication_name
      get :auto_complete_for_publisher_name
      get :auto_complete_for_tag_name
      get :review_batch
      delete :destroy_multiple
    end
    member do
      get :merge_duplicates
    end

    resources :attachments
  end
  #####
  # Person routes
  #####
  resources :people do
    resources :attachments
    resources :works
    resources :groups
    resources :pen_names
    resources :memberships
    resources :roles do
      collection do
        get :new_admin
        get :new_editor
      end
    end
    resources :keywords do
      collection do
        get :timeline
      end
    end
  end

  #####
  # Group routes
  ##### 
  # Add Auto-Complete routes for adding new groups
  resources :groups do
    collection do
      get :auto_complete_for_group_name
      get :hidden
    end
    resources :works
    resources :people
    resources :roles do
      collection do
        get :new_admin
        get :new_editor
      end
    end
    resources :keywords do
      collection do
        get :timeline
      end
    end
  end

  #####
  # Membership routes
  #####
  # Add Auto-Complete routes
  resources :memberships do
    collection do
      get :auto_complete_for_group_name
      put :create_multiple
    end
  end
  
  #####
  # Contributorship routes
  #####
  resources :contributorships do
    collection do
      get :admin
      get :archivable
      put :verify_multiple
      put :unverify_multiple
      put :deny_multiple
    end

    member do
      put :verify
      put :deny
    end
  end
  #####
  # Publisher routes
  #####   
  resources :publishers do
    collection do
      get :authorities
      put :update_multiple
      get :add_to_box
      get :remove_from_box
    end
  end

  #####
  # Publication routes
  #####
  resources :publications do
    collection do
      get :authorities
      put :update_multiple
      get :add_to_box
      get :remove_from_box
    end
  end

  ####
  # User routes
  ####
  # Make URLs like /user/1/password/edit for Users managing their passwords
  resources :users do
    resources :imports
    resource :password
  end

  ####
  # Import routes
  ####
  resources :imports do
    resource :user
    resources :attachments
  end

  ####
  # Search route
  ####
  match 'search', :to => 'search#index', :as => 'search'
  match 'search/advanced', :to => 'search#advanced', :as => 'advanced_search'

  ####
  # Saved routes
  ####
  match 'saved', :to => 'user_sessions#saved', :as => 'saved'
  match 'sessions/delete_saved', :to => 'user_sessions#delete_saved', 
    :as => 'delete_saved'
  match 'sessions/add_many_to_saved', :to => 'user_sessions#add_many_to_saved',
    :as => 'add_many_to_saved'
  ####
  # Authentication routes
  ####
  # Make easier routes for authentication (via restful_authentication)
  match 'signup', :to => 'users#new', :as => 'signup'
  match 'login', :to => 'user_sessions#new', :as => 'login'
  match 'logout', :to => 'user_sessions#destroy', :as => 'logout'
  match 'activate/:activation_code', :to => 'users#activate', :as => 'activate'

  ####
  # DEFAULT ROUTES 
  ####
  # Install the default routes as the lowest priority.
  resources :name_strings
  resources :memberships
  resources :pen_names
  resources :keywords
  resources :keywordings
  resources :sessions
  resources :passwords
  resources :attachments

  # Default homepage to works index action
  root :to => 'works#index'

  match 'citations', :to => 'works#index'

  match ':controller(/:action(/:id))'

  resource :user_session
  
end
