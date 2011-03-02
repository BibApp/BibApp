require File.join(Rails.root, 'spec', 'spec_helper')

describe Exhibition do

  it_should_behave_like "a title_primary validating work subclass", Exhibition,
                        ['Artist', 'Curator'], 'Artist', 'Curator', nil

end
