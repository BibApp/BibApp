require File.join(Rails.root, 'spec', 'spec_helper')

describe BookSection do

  it_should_behave_like "a title_primary validating work subclass", BookSection, ['Author', 'Editor'], 'Author',
                        'Editor', "http://purl.org/eprint/type/BookItem"

end
