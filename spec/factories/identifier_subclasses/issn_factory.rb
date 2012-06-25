FactoryGirl.define do
  factory :issn, :class => ISSN do
    name  {ISSN.random}
  end
end
