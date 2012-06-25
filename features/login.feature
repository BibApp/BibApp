Feature: Login
  In order to allow users to login 
  As the system
  I want to have a login page

  Scenario: Existing user login
    Given I am a local user user@example.com with password local-password
    When I login with email user@example.com and password local-password
    Then I should be logged in

