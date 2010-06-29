#  == Synopsis
#
# Declarations of CSL constants (see http://xbiblio.svn.sourceforge.net/viewvc/xbiblio/csl/schema/trunk/csl.rnc?view=markup)
#
#  == Author
#
#  Liam Magee
#
#  == Copyright
#
#  Copyright (c) 2007, Liam Magee.
#  Licensed under the same terms as Ruby - see http://www.ruby-lang.org/en/LICENSE.txt.
#

module Citeproc
  INFO_FIELDS = [
    "anthropology", "biology", "botany", "chemistry", "engineering", 
    "generic-base", "geography", "geology", "history", "literature", 
    "philosophy", "psychology", "sociology", "political_science", "zoology"
  ]
      
  INFO_CLASSES = [
    "author-date" , "numeric" , "label" , "note" , "in-text"
  ]
  
  TERMS = [
        "accessed", 
        "anonymous",
        "and", 
        "and others", 
        "at", 
        "et-al", 
        "forthcoming", 
        "from", 
        "in press", 
        "ibid", 
        "in", 
        "no date", 
        "references", 
        "retrieved",
    
      ## Roles
      "editor", 
      "translator", 
      
      ## Months
      "month-01", 
      "month-02", 
      "month-03", 
      "month-04", 
      "month-05", 
      "month-06", 
      "month-07", 
      "month-08", 
      "month-09", 
      "month-10", 
      "month-11", 
      "month-12"
  ]
      
  LOCATOR_TERMS = [
    "book", 
    "chapter", 
    "column", 
    "figure", 
    "folio", 
    "issue", 
    "line", "note", 
    "opus", 
    "page", 
    "paragraph", 
    "part", 
    "section", 
    "volume", 
    "verse"
  ]
  
  NAMES = [
    "author", 
    "editor", 
    "translator", 
    "recipient", 
    "interviewer", 
    "publisher", 
    "original-author", 
    "original-publisher"    
  ]
  
  VARIABLES = [
    
    ## the primary title for the cited item
    "title", 
    
      ## the secondary title for the cited item; for a book chapter, this 
      ## would be a book title, for an article the journal title, etc.
      "container-title", 
      
      ## the tertiary title for the cited item; for example, a series title
      "collection-title",
      
      ## title of a related original version; often useful in cases of translation
      "original-title", 
      
      ## the name of the publisher
      "publisher", 
      
      ## the location of the publisher
      "publisher-place",
      
      ## the name of the archive
      "archive",
      
      ## the location of the archive
      "archive-place",
      
      ## the location within an archival collection (for example, box and folder)
      "archive_location",
      
      ## the name or title of a related event such as a conference or hearing
      "event",
      
      ## the location or place for the related event
      "event-place",
      
      ##
      "page",
      
      ## a description to locate an item within some larger container or 
      ## collection; a volume or issue number is a kind of locator, for example.
      "locator",
      
      ## version description
      "version",
      
      ## volume number for the container periodical
      "volume",
      
      ## refers to the number of items in multi-volume books and such
      "number-of-volumes",
      
      ## the issue number for the container publication
      "issue",
      
      ##
      "chapter-number",
      
      ## medium description (DVD, CD, etc.)
      "medium",
      
      ## the (typically publication) status of an item; for example "forthcoming"
      "status",
      
      ## an edition description
      "edition",
      
      ##
      "genre",
      
      ## a short inline note, often used to refer to additional details of the resource
      "note",
      
      ## notes made by a reader about the content of the resource
      "annote",
      
      ##
      "abstract",
      
      ##
      "keyword",
      
      ## a document number; useful for reports and such
      "number",
      
      ##
      "URL",
      
      ##
      "DOI",
      
      ##
      "ISBN",
      
      ## the number used for the in-text citation mark in numeric styles
      "citation-number",
      
      ## the label used for the in-text citation mark in label styles
      "citation-label"
  ]
  
  
  TYPES = [
    "article",
    "article-magazine",
    "article-newspaper", 
    "article-journal", 
    "bill", 
    "book", 
    "chapter", 
    "entry", 
    "entry-dictionary", 
    "entry-encylopedia", 
    "figure", 
    "graphic", 
    "interview", 
    "legislation", 
    "legal_case", 
    "manuscript", 
    "map", 
    "motion_picture", 
    "musical_score", 
    "pamphlet", 
    "paper-conference", 
    "patent", 
    "post", 
    "post-weblog", 
    "personal_communication", 
    "report",
    "review",
    "review-book",
    "song",
    "speech",
    "thesis",
    "treaty",
    "webpage"
  ]


end
