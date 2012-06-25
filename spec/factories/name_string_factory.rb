FactoryGirl.define do
  factory :name_string do
    sequence(:name) {|n| "Name #{n}"}
  end
end
