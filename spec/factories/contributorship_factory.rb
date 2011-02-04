Factory.define(:contributorship)  do |c|
  c.association :person
  c.association :work, :factory => :book_whole
  c.association :pen_name
end