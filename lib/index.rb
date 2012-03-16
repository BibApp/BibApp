require 'solr'
class Index

  #### Solr ####

  # CONNECT
  # SOLRCONN = Solr::Connection.new("http://localhost:8983/solr")
  # SOLRCONN lives in initializers

  # SEARCH
  # q = solr.query("complex", :facets => {:zeros => false, :fields => [:author_facet]})
  # q = solr.query("comp*", {:field_list => ["author_facet"]})
  # q = solr.query("comp*", {:filter_queries => ["type_s:JournalArticle"]})

  # VIEW FACETS
  # @author_facets = @q.field_facets("name_string_facet")

  # DELETE INDEX - Very long process
  # @TODO: Learn how to use Solr "replication"
  ## works.each{|c| Index.remove_from_solr(c)}

  # REINDEX - Very long process
  # @TODO: Learn how to use Solr "replication"
  ## works.each{|c| Index.update_solr(c)}

  # Default Solr Mapping
  SOLR_MAPPING = {
      # Work
      :pk_i => :id, #store Work ID as pk_i in Solr
      :id => Proc.new { |record| record.solr_id }, #create a unique Solr ID for Work
      :title => :title_primary,
      :title_secondary => :title_secondary,
      :title_tertiary => :title_tertiary,
      :sort_title => :sort_name,
      :issue => :issue,
      :volume => :volume,
      :start_page => :start_page,
      :abstract => :abstract,
      :status => :work_state_id,
      :issn_isbn => Proc.new { |record| record.publication.nil? ? nil : record.publication.issn_isbn },

      # Work Type (index as "Journal article" rather than "JournalArticle")
      :type => Proc.new { |record| record[:type].underscore.humanize },

      # NameStrings
      :name_strings => Proc.new { |record| record.name_strings.collect { |ns| ns.name } },
      :name_string_id => Proc.new { |record| record.name_strings.collect { |ns| ns.id } },
      :name_strings_data => Proc.new { |record| record.name_strings.collect { |ns| ns.to_solr_data } },

      # WorkNameStrings
      :authors_data => Proc.new { |record| record.authors.collect { |au| "#{au[:name]}||#{au[:id]}" } },
      :editors_data => Proc.new { |record| record.editors.collect { |ed| "#{ed[:name]}||#{ed[:id]}" } },

      # People
      :people => Proc.new { |record| record.people.collect { |p| p.first_last } },
      :person_id => Proc.new { |record| record.people.collect { |p| p.id } },
      :people_data => Proc.new { |record| record.people.collect { |p| p.to_solr_data } },
      :research_focus => Proc.new {|record| record.people.collect {|p| p.research_focus.dump}},

      #Person's active status in separate field for filtering
      :person_active => Proc.new { |record| record.people.collect { |p| p.person_active } },

      # Groups
      :groups => Proc.new { |record| record.people.collect { |p| p.groups.collect { |g| g.name } }.uniq.flatten },
      :group_id => Proc.new { |record| record.people.collect { |p| p.groups.collect { |g| g.id } }.uniq.flatten },
      :groups_data => Proc.new { |record| record.people.collect { |p| p.groups.collect { |g| g.to_solr_data } }.uniq.flatten },

      # Publication
      :publication => Proc.new { |record| record.publication.nil? ? nil : record.publication.name },
      :publication_id => Proc.new { |record| record.publication.nil? ? nil : record.publication.id },
      :publication_data => Proc.new { |record| record.publication.nil? ? nil : record.publication.to_solr_data },

      # Publisher
      :publisher => Proc.new { |record| record.publisher.nil? ? nil : record.publisher.name },
      :publisher_id => Proc.new { |record| record.publisher.nil? ? nil : record.publisher.id },
      :publisher_data => Proc.new { |record| record.publisher.nil? ? nil : record.publisher.to_solr_data },

      # Keywords
      :keywords => Proc.new { |record| record.keywords.collect { |k| k.name } },
      :keyword_id => Proc.new { |record| record.keywords.collect { |k| k.id } },

      # Tags
      :tags => Proc.new { |record| record.tags.collect { |t| t.name } },
      :tag_id => Proc.new { |record| record.tags.collect { |t| t.id } },

      # Duplication Keys
      :title_dupe_key => Proc.new { |record| record.title_dupe_key },
      :name_string_dupe_key => Proc.new { |record| record.name_string_dupe_key },

      # Timestamps
      :created_at => :created_at,
      :updated_at => :updated_at
  }

  # Mapping specific to dates
  #   Since dates are occasionally null they are only passed to Solr
  #   if the publication_date_year is *not* null.
  SOLR_DATE_MAPPING = SOLR_MAPPING.merge({:year => Proc.new { |record| record.publication_date_year }})


  # Index all Works which have been flagged for batch indexing
  def self.batch_index
    records = Work.to_batch_index

    #Batch index 100 records at a time...wait to commit till the end.
    records.each_slice(100) do |records_slice|
      batch_update_solr(records_slice, false)
    end

    #Mark all these Works as indexed & commit changes to Solr
    records.each do |r|
      r.mark_indexed
    end

    #SOLRCONN.commit
    Index.optimize_index
  end

  def self.start(page, rows)
    if page.to_i < 2
      0
    else
      (page.to_i - 1) * (rows.to_i)
    end
  end


  #Re-index *everything* in Solr
  #  This method is useful in case your Solr index
  #  gets out of sync with your DB
  def self.index_all
    #Delete all existing records in Solr
    SOLRCONN.delete_by_query('*:*')

    #Reindex all Works again
    records = Work.all

    #Do a batch update, 100 records at a time...wait to commit till the end.
    records.each_slice(100) do |records_slice|
      batch_update_solr(records_slice, false)
    end

    SOLRCONN.commit
    Index.build_spelling_suggestions
  end

  def self.build_spelling_suggestions
    SOLRCONN.send(Solr::Request::Spellcheck.new(:command => "rebuild", :query => "physcs"))
  end

  #Update a single record in Solr
  # (for bulk updating, use 'batch_update_solr', as it is faster)
  def self.update_solr(record, commit_records=true)
    doc = solr_doc_from_record(record)

    SOLRCONN.add(doc)
    SOLRCONN.commit if commit_records
  end

  #Batch update several records with a single request to Solr
  def self.batch_update_solr(records, commit_records=true)
    docs = records.collect do |record|
      solr_doc_from_record(record)
    end

    #Send one update request for all docs!
    request = Solr::Request::AddDocument.new(docs)
    SOLRCONN.send(request)
    SOLRCONN.commit if commit_records
  end

  def self.solr_doc_from_record(record)
    if record.publication_date_year
      #add dates to our mapping
      Solr::Importer::Mapper.new(SOLR_DATE_MAPPING).map(record)
    else
      Solr::Importer::Mapper.new(SOLR_MAPPING).map(record)
    end
  end

  #Remove a single record from Solr
  def self.remove_from_solr(record)
    SOLRCONN.delete(record.solr_id)
    SOLRCONN.commit
  end


  def self.optimize_index
    SOLRCONN.optimize
  end

  #Fetch all documents matching a particular query,
  # along with the facets.
  def self.fetch(query_string, filter, sort, order, page, facet_count, rows)

    #Check array of filters to see if work 'status' specified
    filter_by_status = false
    filter.each do |f|
      if f.include?(Work.solr_status_field)
        filter_by_status = true
        break
      end
    end

    #If status unspecified, default to *only* showing "accepted" works
    filter.push(Work.solr_accepted_filter) if !filter_by_status

    #build our list of Solr query parameters
    # Note: the various '*_facet' and '*_facet_data' fields
    # are auto-generated by our Solr schema settings (see schema.xml)
    query_params = {
        :query => query_string,
        :filter_queries => filter,
        :facets => {
            :fields => [
                :group_facet,
                :group_facet_data,
                :keyword_facet,
                :tag_facet,
                :name_string_facet,
                :name_string_facet_data,
                :authors_data,
                :editors_data,
                :person_facet,
                :person_facet_data,
                :publication_facet,
                :publication_facet_data,
                :publisher_facet,
                :publisher_facet_data,
                :type_facet,
                {:year_facet => {:sort => :term}}
            ],
            :mincount => 1,
            :limit => facet_count
        },
        :start => self.start(page, rows),
        :sort => [{sort.to_s => order.to_sym}],
        :rows => rows
    }

    begin
      # First, try query with StandardRequestHandler
      q = SOLRCONN.send(Solr::Request::Standard.new(query_params))

      # Rerun our search if the StandardRequestHandler came up empty...
      if q.data["response"]["docs"].size < 1
        # Try it instead with DismaxRequestHandler, which is more forgiving
        q = SOLRCONN.send(Solr::Request::Dismax.new(query_params))
      end

      # Processing returned docs and extract facets
      docs, facets = process_response(q)

    rescue
      # If anything goes wrong (bad query terms for instance), we want to use the DismaxRequestHandler
      # which will help parse the "junk" from users' queries... and will return 0 results.
      q = SOLRCONN.send(Solr::Request::Dismax.new(query_params))

      # Processing returned docs and extract facets
      docs, facets = process_response(q)
    end

    # return query response, docs and facets
    return q, docs, facets
  end

  #Retrieve Spelling Suggestions from Solr, based on query
  def self.get_spelling_suggestions(query)
    spelling_suggestions = SOLRCONN.send(Solr::Request::Spellcheck.new(:query => query)).suggestions
    if spelling_suggestions == query
      spelling_suggestions = nil
    end

    return spelling_suggestions
  end

  def self.fetch_by_solr_id(solr_id)
    SOLRCONN.send(Solr::Request::Standard.new(:query => "id:#{solr_id}")).data["response"]["docs"]
  end

  # Retrieve recommendations from Solr, based on current Work
  def self.recommendations(work)

    #Send a "more like this" query to Solr
    r = SOLRCONN.send(Solr::Request::Standard.new(
                          :query => "id:#{work.solr_id}",
                          :mlt => {
                              :count => 5,
                              :field_list => ["abstract", "title"]
                          })
    )

    docs = Array.new

    #Add related docs to an array, if any like this one were found
    unless r.data["moreLikeThis"].empty? or r.data["moreLikeThis"]["#{work.solr_id}"].empty?
      r.data["moreLikeThis"]["#{work.solr_id}"]["docs"].each do |doc|
        work = Work.find(doc["pk_i"])
        docs << [work, doc['score']]
      end
    end

    return docs
  end


  # Retrieve possible *accepted* duplicates from Solr, based on current Work
  #   Returns list of document hashes from Solr
  #  Note: if the work itself has been accepted, it will appear in this list
  def self.possible_accepted_duplicates(record)

    work = Hash.new
    #If this is a Work, generate dupe keys dynamically
    if record.kind_of?(Work)
      work['title_dupe_key'] = record.title_dupe_key
      work['name_string_dupe_key'] = record.name_string_dupe_key
    else #otherwise, this is data from Solr, so we already have dupe keys
      work = record
    end

    # Find all 'accepted' works with a matching Title Dupe Key or matching NameString Dupe Key
    query_params = {
        :query => "(title_dupe_key:\"#{work['title_dupe_key']}\" OR name_string_dupe_key:\"#{work['name_string_dupe_key']}\") AND #{Work.solr_accepted_filter}",
        :rows => 3
    }

    #Send a "more like this" query to Solr
    r = SOLRCONN.send(Solr::Request::Standard.new(query_params))

    #get the documents returned by Solr query
    docs = r.data["response"]["docs"]

    return docs
  end

  # Retrieve possible *accepted* duplicates from Solr, based on current Work
  #  Returns a list of Work objects
  #  Note: if the work itself has been accepted, it will appear in this list
  def self.possible_accepted_duplicate_works(work)
    dupes = Array.new

    # Query Solr for all possible duplicates
    #  This returns a hash of document information from Solr
    docs = possible_accepted_duplicates(work)

    #Get the Work corresponding to each doc returned by Solr
    docs.each do |doc|
      dupes << Work.find(doc["pk_i"]) rescue nil
    end
    return dupes.compact
  end

  # Retrieve all possible *unaccepted* duplicates from Solr, based
  # on current Work, and including the current Work itself
  #  Returns a list of Work objects
  #  Note: if the work itself has not been accepted, it will appear in this list
  def self.possible_unaccepted_duplicate_works(work)

    # Find all works with a matching Title Dupe Key or matching NameString Dupe Key
    query_params = {
        :query => "(title_dupe_key:\"#{work.title_dupe_key}\" OR name_string_dupe_key:\"#{work.name_string_dupe_key}\") AND (#{Work.solr_duplicate_filter})",
        :rows => 3
    }

    #Send a "more like this" query to Solr
    r = SOLRCONN.send(Solr::Request::Standard.new(query_params))

    #get the documents returned by Solr query
    docs = r.data["response"]["docs"]

    #Get the Work corresponding to each doc returned by Solr
    return docs.collect { |doc| Work.find(doc["pk_i"]) }
  end

  private

  #Process the response returned from a Solr query,
  # and extract out the documents & facets
  def self.process_response(query_response)

    #get the documents returned by Solr query
    docs = query_response.data["response"]["docs"]

    # Extract our facets from the query response.
    #  These come back as arrays of Solr::Response::Standard::FacetValue
    #  objects (e.g.) {:name="Sage Publications", 'value'=20}
    #  Note: the various '*_facet' and '*_facet_data' fields
    #  are auto-generated by our Solr schema settings (see schema.xml)
    facets = {
        :people => query_response.field_facets("person_facet"),
        :people_data => query_response.field_facets("person_facet_data"),
        :groups => query_response.field_facets("group_facet"),
        :groups_data => query_response.field_facets("group_facet_data"),
        :names => query_response.field_facets("name_string_facet"),
        :names_data => query_response.field_facets("name_string_facet_data"),
        :authors_data => query_response.field_facets("authors_data"),
        :editors_data => query_response.field_facets("editors_data"),
        :publications => query_response.field_facets("publication_facet"),
        :publications_data => query_response.field_facets("publication_facet_data"),
        :publishers => query_response.field_facets("publisher_facet"),
        :publishers_data => query_response.field_facets("publisher_facet_data"),
        :keywords => query_response.field_facets("keyword_facet"),
        :tags => query_response.field_facets("tag_facet"),
        :types => query_response.field_facets("type_facet"),
        :years => query_response.field_facets("year_facet")
    }

    return docs, facets
  end

end
