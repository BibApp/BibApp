class RssController < ApplicationController
  
  def person
    @person = Person.find(params[:id])
    @citations = @person.citations[-20, 20]
    headers["Content-Type"] = "text/xml"
    render :layout => false
  end
  
  def group
    @group = Group.find(params[:id])
    @citations = @group.citations[-20, 20]
    headers["Content-Type"] = "text/xml"
    render :layout => false
  end
end
