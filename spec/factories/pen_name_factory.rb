FactoryGirl.define do
  factory :pen_name do
    association :person
    association :name_string
  end
end
