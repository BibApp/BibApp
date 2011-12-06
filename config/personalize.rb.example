####
# Personalization Globals
####

####
# Note that as of Bibapp 1.2 some of the strings that used to go here will instead go into locale files
# in config/locales/personalize. The rule of thumb is that these will be strings that require translation
# into each locale you'll be using, e.g. the former $SHERPA_COLORS will instead be in en.yml (and de.yml or whatever
# your other locales are) located at en:personalize:sherpa_colors:.
# The config/locales/personalize/en.yml.example file gives an example of how this may be filled out, and there
# are comments in this file about what has moved.
####


# System Administrator
# - Will receive application error emails
$SYSADMIN_NAME                   = "John Foo Bar"
$SYSADMIN_EMAIL                  = "john_foo_bar@corge.edu"
$NO_REPLY_EMAIL                  = "no-reply@corge.edu"

# Name & base URL of your BibApp Application
#moved to locale file
#$APPLICATION_NAME            = "UW BibApp"
$APPLICATION_URL             = "http://localhost:3000/"
# moved to locale file
#$APPLICATION_TAGLINE         = "Find experts on campus... Promote their research... Archive their work"
#Logo - place image in [bibapp]/public/images/
$APPLICATION_LOGO            = "bibapp.png"

# Name of your University and University URL
#moved to locale file
#$UNIVERSITY_FULL_NAME        = "University of Wisconsin - Madison"
#$UNIVERSITY_SHORT_NAME       = "UW-Madison"
$UNIVERSITY_URL              = "http://wisc.edu"

# Name of your University Library and Library URL
#moved to locale file
#$LIBRARY_NAME                = "Wendt Library"
$LIBRARY_URL                 = "http://wendt.library.wisc.edu"

# Full Address / Contact info of Unit running BibApp
#moved to locale file
#$UNIVERSITY_FULL_ADDRESS     = "215 N. Randall Avenue Madison, WI 53706-1494 | Phone: 608.890.0787"

# Name and URL of your local institutional repository (only used if SWORD plugin is enabled)
#moved to locale file
#$REPOSITORY_NAME = "My Repository"
$REPOSITORY_BASE_URL = "http://my.repository.edu/"

####
# Linking To Publications
#
# The following two variables are used to
# find an article in your library's
# database(s) via OpenURL.
#
# The link created by the following variables will
# be of the form $WORK_BASE_URL?$WORK_SUFFIX,
# i.e. the search is done by using 'get.'
#
# $WORK_BASE should be the first part of the URL
# your institution uses to search for Publications/Works
# up to the '?.'
#
# $WORK_SUFFIX can be used as follows.  Any valid
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
# $WORK_SUFFIX = "id=bibapp&amp;atitle=[title]&amp;date=[year]&amp;issn=[issn]&amp;issue=[issue]&amp;volume=[vol]&amp;spage=[fst]"
####
# moved to locale file
#$WORK_LINK_TEXT          = "Find It"
$WORK_BASE_URL           = "http://sfx.wisconsin.edu/wisc"
$WORK_SUFFIX             = "ctx_enc=info%3Aofi%2Fenc%3AUTF-8&amp;ctx_id=10_1&amp;ctx_tim=2006-5-11T13%3A11%3A1CDT&amp;ctx_ver=Z39.88-2004&amp;res_id=http%3A%2F%2Fsfx.wisconsin.edu%2Fwisc&amp;rft.atitle=[title]&amp;rft.date=[year]&amp;rft.issn=[issn]&amp;rft.issue=[issue]&amp;rft.volume=[vol]&amp;rft.spage=[fst]"

####
# Sherpa Color Explanations
#
# These are the out-of-the-box explanations for each of
# the SHERPA RoMEO "color" rankings for publishers/publications.
# moved to locale file
#$SHERPA_COLORS = {
#  :green    => "Can archive pre-print and post-print",
#  :blue     => "Can archive post-print (i.e. final draft post-refereeing)",
#  :yellow   => "Can archive pre-print (i.e. pre-refereeing)",
#  :white    => "Archiving not formally supported",
#  :unknown  => "Could not determine from data"
#}

####
# Sherpa API URL
#
# Used to retrieve publisher information from the latest SHERPA API.
$SHERPA_API_URL = "http://www.sherpa.ac.uk/romeo/api24.php?all=yes&showfunder=none"

####
# BibApp Status Explanations
#
# These are the out-of-the-box explanations for each of
# the states that a work in the BibApp system can go through.
# moved to locale file
#$WORK_STATUS = {
#  1 => "Processing",
#  2 => "Duplicate",
#  3 => "Accepted"
#}

####
# BibApp Archival Status Explanations
#
# These are the out-of-the-box explanations for each of
# the archival states associated with a work whose file(s)
# are being preserved in a repository.
# move to locale file
#$WORK_ARCHIVE_STATUS = {
#  1 => "Not Ready, rights unknown",
#  2 => "Ready for archiving",
#  3 => "Repository record created, URL known"
#}

####
# BibApp Advanced Search Examples
#
# These are out-of-the-box examples of how to
# enter search queries in the Advanced Search form.
# moved to locale file
#$SEARCH_EXAMPLES ={
#  :keywords   => "ex. plasma confinement physics",
#  :title      => "ex. Transport Phenomena",
#  :authors    => "ex. Corradini, Michael",
#  :groups     => "ex. Engineering Physics",
#  :issn_isbn  => "ex. 0003-018X",
#  :year       => "ex. 2006  to  2008"
#}

####
# Display Keywords and Abstracts
#
# Copyright restrictions may prohibit the display of abstracts
# and keywords. Set this value to 'false' to prevent abstracts
# and keywords from displaying on work pages.
$DISPLAY_ABSTRACTS_AND_KEYWORDS = true

####
# Export Keywords and Abstracts
#
# Similar to the $DISPLAY_ABSTRACTS_AND_KEYWORDS directive above,
# set this value to 'false' to prevent abstracts and keywords from
# being exported via web services (xml, yml, json).
$EXPORT_ABSTRACTS_AND_KEYWORDS = true

####
# Google Analytics
#
# The standard GA tracking code script will be displayed at the
# bottom of every page.
$DISPLAY_GOOGLE_ANALYTICS = false
$GOOGLE_ANALYTICS_ID = "UA-xxxxxx-x"
