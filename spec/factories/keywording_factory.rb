FactoryGirl.define do
  factory :keywording do
    association :work, :factory => :book_whole
    association :keyword
  end
end
