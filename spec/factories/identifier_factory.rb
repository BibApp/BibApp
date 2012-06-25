FactoryGirl.define do
  factory :identifier do
    sequence(:name) { |n| "id-#{n}" }
    type 'Identifier'
  end
end
