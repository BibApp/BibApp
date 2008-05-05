# A Ruby-based SWORD Client
#
# This allows you to make requests (via HTTP) to an existing
# SWORD Server, including posting a file to a SWORD server.
#
# For more information on SWORD and the SWORD APP Profile:
#  http://www.ukoln.ac.uk/repositories/digirep/index/SWORD
class SwordClient; end
  
require 'sword_client/connection'
require 'sword_client/source_doc_handler'
require 'sword_client/post_response_handler'
require 'sword_client/response'