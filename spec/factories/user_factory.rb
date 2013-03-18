FactoryGirl.define do
  factory :unactivated_user, :class => User do
    sequence(:email) { |n| "User_#{n}@example.com" }
    password 'password'
    password_confirmation 'password'
    persistence_token ''
    factory :activated_user, :aliases => [:user] do
      after(:create) {|u| u.activate}
    end

  end
end

