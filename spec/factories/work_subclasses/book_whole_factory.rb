Factory.define :book_whole do |bw|
  bw.sequence(:title_primary) {|n| "Book Title #{n}"}
  bw.type 'BookWhole'
end
