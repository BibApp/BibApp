require File.join(Rails.root, 'spec', 'spec_helper')

describe Monograph do

  it_should_behave_like "a title_primary validating work subclass", Monograph,
                        ['Author', 'Editor', 'Translator', 'Illustrator'], 'Author',
                        'Editor', "http://purl.org/eprint/type/Book"

end
