FactoryGirl.define do
  factory :isbn, :class => ISBN do
    name {ISBN.random}
  end
end
