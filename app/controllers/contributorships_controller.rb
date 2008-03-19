class ContributorshipsController < ApplicationController
  make_resourceful do
    build :all
    
      before :index do
        if params[:person_id]
          @current_objects = Contributorship.find(
            :all, 
            :conditions => ["person_id = ?", params[:person_id]]
          )
        end
      end
  end
end
