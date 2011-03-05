Factory.define :tag do |t|
  t.sequence(:name) {|n| "Tag #{n}"}
end