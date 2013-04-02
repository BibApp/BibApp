FactoryGirl.define do
  factory :work_name_string do
    association :name_string
    association :work, :factory => :book_whole
    role 'Author'
  end
end
