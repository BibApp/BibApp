Factory.define(:issn, :class => ISSN) do |issn|
  issn.name  {ISSN.random}
end
