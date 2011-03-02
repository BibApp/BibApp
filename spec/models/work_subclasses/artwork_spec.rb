require File.join(Rails.root, 'spec', 'spec_helper')

describe Artwork do

  it_should_behave_like "a title_primary validating work subclass", Artwork,
                        ['Artist', 'Curator'], 'Artist',
                        'Curator', "http://purl.org/dc/dcmitype/Image"
end
