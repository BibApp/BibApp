Factory.define :work_name_string do |wns|
  wns.association :name_string
  wns.association :work, :factory => :book_whole
  wns.role 'Author'
end