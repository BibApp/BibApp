require File.join(Rails.root, 'spec', 'spec_helper')

describe Report do

  it_should_behave_like "a title_primary validating work subclass", Report, ['Author', 'Editor'],
                        'Author', 'Editor', "http://purl.org/eprint/type/Report"

end
