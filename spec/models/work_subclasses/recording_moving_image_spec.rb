require File.join(Rails.root, 'spec', 'spec_helper')

describe RecordingMovingImage do

  it_should_behave_like "a title_primary validating work subclass", RecordingMovingImage,
                        ['Director', 'Producer', 'Actor', 'Performer'],
                        'Director', 'Performer', "http://purl.org/dc/dcmitype/MovingImage"


end