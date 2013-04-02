Given /^I am a local user (.*) with password (.*)$/ do |email, password|
  create(:user, :email => email, :password => password, :password_confirmation => password)
end

When /^I login with email (.*) and password (.*)$/ do |email, password|
  visit '/login'
  fill_in 'user_session_email', :with => email
  fill_in 'user_session_password', :with => password
  click_on 'Log in'
end

Then /^I should be logged in$/ do
  page.should have_content('Logout')
end
