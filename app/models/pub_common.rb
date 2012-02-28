#This is an awful name for a class, but the result will be good.
#This aims to abstract out common code from Publication and Publisher,
#of which there is a good deal.
require 'machine_name'
require 'stop_word_name_sorter'
require 'solr_helper_methods'
require 'solr_updater'

class PubCommon < ActiveRecord::Base
  self.abstract_class = true

  include MachineNameUpdater
  include StopWordNameSorter
  include SolrHelperMethods
  include SolrUpdater

  attr_accessor :do_reindex

  # Convert object into semi-structured data to be stored in Solr
  def to_solr_data
    "#{name}||#{id}"
  end

  def authority_for
    self.class.for_authority(self.id)
  end

  def solr_filter
    %Q(#{self.class.to_s.downcase}_id:"#{self.id}")
  end

  def reindex_callback
    Index.batch_index
  end

  # return the first letter of each name, ordered alphabetically
  def self.letters(upcase = nil)
    letters = self.select('DISTINCT SUBSTR(name, 1, 1) AS letter').order('letter').collect { |x| x.letter } - [' ']
    letters = letters.collect { |x| x.upcase } if upcase
    return letters
  end

  def self.update_multiple(pub_ids, auth_id)
    pub_ids.each do |pub|
      update = self.find_by_id(pub)
      update.authority_id = auth_id
      update.do_reindex = false
      update.save
    end
    Index.batch_index
  end

  def get_associated_works
    self.works
  end

  def require_reindex?
    self.authority_id_changed? or self.name_changed? or self.machine_name_changed?
  end

  def initialize_authority_id
    self.authority_id = self.id
    self.save
  end

end