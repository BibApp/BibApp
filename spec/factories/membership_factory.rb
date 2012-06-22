Factory.define(:membership)  do |m|
  m.association :person
  m.association :group
end