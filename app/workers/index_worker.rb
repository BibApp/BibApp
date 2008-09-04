#IndexWorker
#  Performs behind-the-scenes indexing using Solr
#  Uses the Workling plugin (http://github.com/purzelrakete/workling/)
class IndexWorker < Workling::Base
  
  #Update Solr index for a list of Works
  # This is done asynchronously using the Workling plugin
  def update_index(works)
    Index.batch_update_solr(works) if !works.nil? and !works.empty?
  end
   
end
