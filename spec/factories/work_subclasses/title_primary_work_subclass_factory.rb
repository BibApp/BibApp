#Make a factory for each work subclass that requires a title_primary
#Currently they all do, but we list explicitly in anticipation of that not being the case.
FactoryGirl.define do
  [Artwork, BookReview, BookSection, BookWhole, Composition, ConferencePaper,
   ConferencePoster, ConferenceProceedingWhole, DissertationThesis, Exhibition,
   Generic, Grant, JournalArticle, JournalWhole, Monograph, Patent, Performance,
   PresentationLecture, RecordingMovingImage, RecordingSound, Report, WebPage].each do |wsc|
    class_name = wsc.to_s
    factory class_name.underscore.to_sym do
      sequence(:title_primary) { |n| "#{class_name.humanize} Title #{n}" }
      type class_name
    end
  end
end