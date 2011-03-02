require File.join(Rails.root, 'spec', 'spec_helper')

describe ConferencePoster do

 it_should_behave_like "a title_primary validating work subclass", ConferencePoster,
                       ['Author', 'Editor'], 'Author',
                        'Editor', "http ://purl.org/eprint/type/ConferencePoster"
end
