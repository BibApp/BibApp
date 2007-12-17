####
# Personalization Globals
####

$APPLICATION_NAME            = "UW BibApp"
$UNIVERSITY_FULL_NAME        = "University of Wisconsin - Madison" 
$UNIVERSITY_SHORT_NAME       = "UW-Madison"
$UNIVERSITY_URL              = "http://wisc.edu"
$LIBRARY_NAME                = "Wendt Library"
$LIBRARY_URL                 = "http://wendt.library.wisc.edu"
$DEFAULT_STATE               = "WI"
$DEFAULT_CITY                = "Madison"
$DEFUALT_ZIP_CODE            = "53706"
$UNIVERSITY_FULL_ADDRESS     = "215 N. Randall Avenue Madison, WI 53706-1494 | Phone: 608.890.0787"

####
# Linking To Publications
#
# The following two variables are used to 
# link to an article in your library's
# database.  
#
# The link created by the following variables will
# be of the form $CITATION_BASE_URL?$CITATION_SUFFIX,
# i.e. the search is done by using 'get.'
#
# $CITATION_BASE should be the first part of the URL
# your institution uses to search for Publications/Citations
# up to the '?.'
#
# $CITATION_SUFFIX can be used as follows.  Any valid
# string of URL characters can be used.  Then use the following
# convensions for the publication itself can be used.
#
# Title =>                      [title]
# Publication year =>           [year]
# issn/isbn =>                  [issn]
# Issue =>                      [issue]
# Volume =>                     [vol]
# First Page of the Publication [fst]
#
# Below is an example of a suffix:
# $CITATION_SUFFIX = "id=bibapp&amp;atitle=[title]&amp;date=[year]&amp;issn=[issn]&amp;issue=[issue]&amp;volume=[vol]&amp;spage=[fst]"
####
$CITATION_BASE_URL           = "http://sfx.wisconsin.edu/wisc"
$CITATION_SUFFIX             = "ctx_enc=info%3Aofi%2Fenc%3AUTF-8&amp;ctx_id=10_1&amp;ctx_tim=2006-5-11T13%3A11%3A1CDT&amp;ctx_ver=Z39.88-2004&amp;res_id=http%3A%2F%2Fsfx.wisconsin.edu%2Fwisc&amp;rft.atitle=[title]&amp;rft.date=[year]&amp;rft.issn=[issn]&amp;rft.issue=[issue]&amp;rft.volume=[vol]&amp;rft.spage=[fst]"