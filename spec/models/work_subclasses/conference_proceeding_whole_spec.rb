require File.join(Rails.root, 'spec', 'spec_helper')

describe ConferenceProceedingWhole do

  it_should_behave_like "a title_primary validating work subclass", ConferenceProceedingWhole, ['Editor'], 'Editor',
                        'Editor', "http://purl.org/eprint/type/ConferenceItem"
end
