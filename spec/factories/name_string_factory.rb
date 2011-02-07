Factory.define :name_string do |ns|
  ns.sequence(:name) {|n| "Name #{n}"}
end