require File.dirname(__FILE__) + '/../spec_helper'

describe SearchController do

  it "provides search via the index action" do
    controller.should_receive(:search)
    get :index
    response.should be_success
    response.should render_template(:index)
  end

  it "provides an advanced search action" do
    get :advanced
    response.should be_success
    response.should render_template(:advanced)
  end

end
