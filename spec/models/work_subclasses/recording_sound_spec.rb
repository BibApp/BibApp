require File.join(Rails.root, 'spec', 'spec_helper')

describe RecordingSound do

  it_should_behave_like "a title_primary validating work subclass", RecordingSound,
                        ['Musician', 'Performer', 'Interviewer', 'Interviewee', 'Musical Ensemble'],
                        'Performer', 'Performer', "http://purl.org/dc/dcmitype/Sound"

end
