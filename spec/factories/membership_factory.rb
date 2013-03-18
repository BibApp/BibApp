FactoryGirl.define do
  factory :membership do
    association :person
    association :group
  end
end
