Factory.define(:isbn, :class => ISBN) do |isbn|
  isbn.name {ISBN.random}
end