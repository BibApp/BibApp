FactoryGirl.define do
  factory :person do
    sequence(:uid) { |n| n }
    sequence(:first_name) { |n| "First_name_#{n}" }
    sequence(:middle_name) { |n| "Middle_name_#{n}" }
    sequence(:last_name) { |n| "Last_name_#{n}" }
  end
end

