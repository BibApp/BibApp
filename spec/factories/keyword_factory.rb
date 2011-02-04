Factory.define :keyword do |k|
  k.sequence(:name) {|n| "Keyword_#{n}"}
end