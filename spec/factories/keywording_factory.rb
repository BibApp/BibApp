Factory.define(:keywording) do |k|
  k.association :work, :factory => :book_whole
  k.association :keyword
end