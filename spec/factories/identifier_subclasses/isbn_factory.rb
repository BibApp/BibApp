Factory.define(:isbn) do |isbn|
  isbn.name {ISBN.random}
end