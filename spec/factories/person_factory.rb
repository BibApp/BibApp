Factory.define(:person) do |p|
  p.sequence(:uid) { |n| n }
  p.sequence(:first_name) { |n| "First_name_#{n}" }
  p.sequence(:middle_name) { |n| "Middle_name_#{n}" }
  p.sequence(:last_name) { |n| "Last_name_#{n}" }
end