FactoryGirl.define do
  factory :keyword do
    sequence(:name) {|n| "Keyword_#{n}"}
  end
end

