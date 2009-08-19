class Publication < ActiveRecord::Base
  
  
  #### Associations ####
  
  belongs_to :publisher
  belongs_to :authority,
    :class_name => "Publication",
    :foreign_key => :authority_id
  has_many :works, :conditions => ["work_state_id = ?", 3] #accepted works
  
  has_many :identifyings, :as => :identifiable
  has_many :identifiers, :through => :identifyings
  
  
  #### Callbacks ####
  
  #Called after create only
  def after_create
    #Authority defaults to self
    self.authority_id = self.id
    self.save
  end
  
  #Note: 'after_save' callback is located in 'publication_observer.rb', to make
  # sure it is called *before* after_save in 'index_observer.rb'
  # (That way Publication info is updated completely *before* re-indexing of works)
  
  #### Methods ####
  
  def isbns
    isbns = Array.new
    ids = self.identifiers.find(:all, :conditions => [ 'type=?', 'ISBN']).collect{|isbn| {:name => isbn.name, :id => isbn.id}}
    ids.each do |id|
      isbns << {:name => id[:name], :id => id[:id]}
    end
    return isbns
  end
  
  def issns
    issns = self.identifiers.find(:all, :conditions => [ 'type=?', 'ISSN']).collect{|issn| {:name => issn.name, :id => issn.id}}
  end
  
  def parse_identifiers
    if self.issn_isbn.blank?
      return
    else
      # Loop thru all publication issn_isbn values
      self.issn_isbn.each do |issn_isbn| 

        # Field might be separated
        issn_isbn.split("; ").each do |identifier|

          # No spaces, no hyphens, no quotes -- @TODO: Do this better!
          identifier = identifier.strip.gsub(" ", "").gsub("-", "").gsub('"', "")

          # Init new Identifier
          id = Identifier.new
          parsed_id = id.parse(identifier)
          if !parsed_id[0].blank?
            pub_id = Identifier.find_or_initialize_by_name(:name => parsed_id[1])
            pub_id[:type] = parsed_id[0] if !parsed_id[0].blank?
            pub_id.save
            if self.identifiers.include?(pub_id)
              # Do nothing
            else
              self.identifiers << pub_id
            end
            self.save_without_callbacks
          else
            # Do Nothing
          end
        end
      end
    end
  end
  
  def save_without_callbacks
    update_without_callbacks
  end
  
  def to_param
    param_name = name.gsub(" ", "_")
    param_name = param_name.gsub(/[^A-Za-z0-9_]/, "")
    "#{id}-#{param_name}"
  end
  
  # Convert object into semi-structured data to be stored in Solr
  def to_solr_data
    "#{name}||#{id}"
  end

  def form_select
    "#{name.first(100)+"..."} - #{issn_isbn}"
  end

  def authority_for
    authority_for = Publication.find(
      :all, 
      :conditions => ["authority_id = ?", self.id]
    )
    return authority_for
  end
  
  def authority_for_work_count
    works = Array.new
    self.authority_for.each do |publication|
      works << publication.works.size
    end
    
    # Sum a ruby array of work counts
    return works.inject( 0 ) { |sum,x| sum+x }
  end
  
  #Update authorities for related models, when Publication Authority changes
  # (called by after_save callback)
  def update_authorities
    # If Publication authority changed, we need to echo new authority key
    # to each related model.
    logger.debug("\n\nPub: #{self.id} | Auth: #{self.authority_id}\n\n")
    if self.authority_id_changed? and self.authority_id != self.id
      
      # Update publications
      logger.debug("\n\n===Updating Publications===\n\n")
      self.authority_for.each do |pub|
        pub.authority_id = self.authority_id
        pub.save
      end
      
      # Update works
      logger.debug("\n\n===Reindexing Works===\n\n")
      Index.batch_update_solr(self.works)
    end
  end
  
  #Update Machine Name of Publication (called by after_save callback)
  def update_machine_name
    #Machine name only needs updating if there was a name change
    if self.name_changed?
      #Machine name is Name with:
      #  1. all punctuation/spaces converted to single space
      #  2. stripped of leading/trailing spaces and downcased
      self.machine_name = self.name.mb_chars.gsub(/[\W]+/, " ").strip.downcase
      self.save_without_callbacks
    end
  end
  
  class << self

    # return the first letter of each name, ordered alphabetically
    def letters
      find(
        :all,
        :select => 'DISTINCT SUBSTR(name, 1, 1) AS letter',
        :order  => 'letter'
      )
    end
  
    def update_multiple(pub_ids, auth_id)
      pub_ids.each do |pub|
        update = Publication.find_by_id(pub)
        update.authority_id = auth_id
        update.save
      end
    end
    
    #Parse Solr data (produced by to_solr_data)
    # return Publication name and ID
    def parse_solr_data(publication_data)
      data = publication_data.split("||")
      name = data[0]
      id = data[1]  
      
      return name, id
    end
  end
end
