#Much of the time one is going to want to use a work subclass, as there are some methods defined there
#that aren't in the base class.
Factory.define :work do |w|
  w.sequence(:title_primary) {|n| "Primary Title #{n}"}
  w.type 'BookWhole'
end

