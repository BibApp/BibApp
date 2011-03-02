require File.join(Rails.root, 'spec', 'spec_helper')

describe Performance do

 it_should_behave_like "a title_primary validating work subclass", Performance,
                       ['Director', 'Conductor', 'Actor', 'Musician', 'Dancer', 'Costume Designer', 'Lighting Designer',
                        'Choreographer', 'Composer', 'Producer', 'Orchestra', 'Band', 'Choir', 'Other'],
                       'Director', 'Musician', nil

end
