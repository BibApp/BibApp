#IndexWorker
#  Performs behind-the-scenes indexing using Solr
#  Uses the Workling plugin (http://github.com/purzelrakete/workling/)
class IndexWorker < Workling::Base
  
  #Update Solr index for a list of citations
  # This is done asynchronously using the Workling plugin
  def update_index(citations)
    Index.batch_update_solr(citations) if !citations.nil? and !citations.empty?
  end
   
end
