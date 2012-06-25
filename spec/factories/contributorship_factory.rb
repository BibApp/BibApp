FactoryGirl.define do
  factory :contributorship do
    association :person
    association :work, :factory => :book_whole
    association :pen_name
  end
end
