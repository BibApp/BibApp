class PublishersController < ApplicationController
  before_filter :find_publisher, :only => [:edit, :update]
  
  def index
    @publishers = Publisher.find(:all)
  end
  
  def edit
  end
  
  def update
    @publisher.update_attributes!(params[:publisher])
    redirect_to publishers_path
  end
  
  private
  def find_publisher
    @publisher = Publisher.find(params[:id])
  end
end
