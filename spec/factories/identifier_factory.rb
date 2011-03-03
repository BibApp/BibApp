Factory.define(:identifier) do |i|
  i.sequence(:name) {|n| "id-#{n}"}
  i.type 'Identifier'
end