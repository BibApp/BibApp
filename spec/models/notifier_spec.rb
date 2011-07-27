require File.dirname(__FILE__) + '/../spec_helper'

describe Notifier do
  include EmailSpec::Helpers
  include EmailSpec::Matchers
  include ActionController::UrlWriter

  describe "import review notification" do
    before(:each) do
      @user = Factory.create(:user)
      @import = Factory.create(:import, :user => @user)
      @email = Notifier.create_import_review_notification(@user, @import)
    end

    it "should be delivered to the user's email address" do
      @email.should deliver_to(@user.email)
    end

    it "should say that an import is ready in the subject" do
      @email.should have_subject(/BibApp/)
      @email.should have_subject(/import ready/)
    end

    it "should have a link to the import review page" do
      @email.should have_body_text(/#{imports_path(@import)}/)
    end

  end


end
