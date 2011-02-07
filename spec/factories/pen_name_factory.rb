Factory.define(:pen_name) do |pn|
  pn.association :person
  pn.association :name_string
end