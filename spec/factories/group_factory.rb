FactoryGirl.define do
  factory :group do
    sequence(:name) {|n| "Group #{n}"}
    hide false
  end
end
