require File.join(Rails.root, 'spec', 'spec_helper')

describe BookWhole do

  it_should_behave_like "a title_primary validating work subclass", BookWhole,
                        ['Author', 'Editor', 'Translator', 'Illustrator'],
                        'Author', 'Editor', "http://purl.org/eprint/type/Book"
end
