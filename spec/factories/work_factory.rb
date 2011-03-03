#Much of the time one is going to want to use a work subclass, as there are some methods defined there
#that aren't in the base class.
Factory.define :abstract_work, :class => Work do |w|
  w.sequence(:title_primary) {|n| "Primary Title #{n}"}
  w.type 'BookWhole'
end

#We use a specific work subclass because some of the work methods
#depend on the interface that all the subclasses implement working.
Factory.define :work, :class => BookWhole do |w|
  w.sequence(:title_primary) {|n| "Primary Title #{n}"}
  w.type 'BookWhole'
end
