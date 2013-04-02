#Much of the time one is going to want to use a work subclass, as there are some methods defined there
#that aren't in the base class.
FactoryGirl.define do
  sequence :title_primary do |n|
    "Primary Title #{n}"
  end

  factory :abstract_work, :class => Work do
    type 'BookWhole'
    title_primary
  end

  factory :work, :class => BookWhole do
    type 'BookWhole'
    title_primary
  end
end

