# Methods added to this helper will be available to all templates in the application.
module ApplicationHelper
  require 'config/personalize.rb'
  require 'htmlentities'
  
  def ajax_checkbox_toggle(model, person, selected)
    person = Person.find(person.id)
    if selected
      js = remote_function(
        :url => {
          :action => :destroy,
          :person_id => person.id, 
          "#{model.class.to_s.tableize.singularize}_id".to_sym => model.id},
        :method => :delete
      )
    else
      js = remote_function(
        :url => {
          :action => :create,
          :person_id => person.id, 
          "#{model.class.to_s.tableize.singularize}_id".to_sym => model.id
          },
        :method => :post
      )
    end
    check_box_tag("#{model.class.to_s.tableize.singularize}_#{model.id}_toggle", 1, selected, :onclick => js)
  end

  def letter_link_for(letters, letter, current)
    if current == true
      content_tag(:li, (letters.index(letter) ? link_to(letter, {:page=> letter}, :class => "some") : content_tag(:a, letter, :class => 'none')), :class => "current")
    else
      content_tag :li, (letters.index(letter) ? link_to(letter, {:page=> letter}, :class => "some") : content_tag(:a, letter, :class => 'none'))
    end
  end
  
  def object_by_facet_id(name)
    klass,id = name.split("-")
    object = klass.constantize.find(id)
    object
  end
  
  def link_to_related_citations(citation)
    #link_to "Related Citations", search_url(:q => "id:#{citation-solr_id}", :qt  => "mlt")
    "Related Citations"
  end
  
  def link_to_download_from_archive(citation)
    #link_to "Download from #{$REPOSITORY_NAME}"
    "Download from #{$REPOSITORY_NAME}"
  end

  def link_to_findit(citation)
  	#start w/default suffix to "Find It!"
  	suffix = $CITATION_SUFFIX

=begin
  	logger.debug("IP: #{request.env["HTTP_X_FORWARDED_FOR"] }")
  	client = ResolverRegistry::Client.new
    institution = client.lookup(@remote_ip)
    suffix = institution.resolver.base_url
=end

	#Substitute citation title
  	suffix = (citation.title_primary.nil?) ? suffix.gsub("[title]", "") : suffix.gsub("[title]", citation.title_primary.to_s.sub(" ", "+"))
  	
	#Substitute citation year
	suffix = (citation.publication_date.nil?) ? suffix.gsub("[year]", "") : suffix.gsub("[year]", citation.publication_date.year.to_s)
	
	#Substitute citation issue
	suffix = (citation.issue.nil?) ? suffix.gsub("[issue]", "") : suffix.gsub("[issue]", citation.issue.to_s)	
	
	#Substitute citation volume
	suffix = (citation.volume.nil?) ? suffix.gsub("[vol]", "") : suffix.gsub("[vol]", citation.volume.to_s)	
	
	#Substitute citation start-page
	suffix = (citation.start_page.nil?) ? suffix.gsub("[fst]", "") : suffix.gsub("[fst]", citation.start_page)	
		
	#Substitute citation ISSN/ISBN
	suffix = (citation.publication.nil? || citation.publication.issn_isbn.nil?) ? suffix.gsub("[issn]", "") : suffix.gsub("[issn]", citation.publication.issn_isbn)	
		
    link_to "Find it", "#{$CITATION_BASE_URL}?#{suffix}"
  end
  
  def coins(citation)
    coins = "ctx_ver=Z39.88-2004&amp;rft_val_fmt=info%3Aofi%2Ffmt%3Akev%3Amtx%3Abook&amp;rft.btitle=The+Wind+in+the+Willows&amp;rft.au=Grahame,+Kenneth"
=begin
    # Journal - http://ocoins.info/cobg.html
    rft.atitle
    rft.title 
    rft.jtitle 
    rft.stitle 
    rft.date 
    rft.volume 
    rft.issue 
    rft.spage 
    rft.epage 
    rft.pages 
    rft.artnum 
    rft.issn 
    rft.eissn 
    rft.aulast 
    rft.aufirst 
    rft.auinit 
    rft.auinit1 
    rft.auinitm 
    rft.ausuffix 
    rft.au 
    rft.aucorp 
    rft.isbn 
    rft.coden 
    rft.sici 
    rft.genre 
    rft.chron 
    rft.ssn 
    rft.quarter 
    rft.part 
    
    #Book - http://ocoins.info/cobgbook.html
    rft.btitle
    rft.isbn 
    rft.aulast 
    rft.aufirst 
    rft.auinit 
    rft.auinit1 
    rft.auinitm 
    rft.ausuffix 
    rft.au 
    rft.aucorp 
    rft.atitle 
    rft.title 
    rft.place 
    rft.pub 
    rft.date 
    rft.edition 
    rft.tpages 
    rft.series 
    rft.spage 
    rft.epage 
    rft.pages 
    rft.issn 
    bici 
    rft.genre 
=end
  end
  
  def archivable_count
    if Publisher.find(:all, :conditions => ["publisher_copy = '1'"]).empty?
      return @archivable_count = 0
    end
    
    archivable_publishers = Publisher.find(
      :all, 
      :select => "pub1.id, pub2.id as auth", 
      :from => "publishers pub1", 
      :joins => "join publishers pub2 on pub1.id = pub2.authority_id", 
      :conditions => "pub1.publisher_copy = 1"
    )

    pub_ids = Array.new
    archivable_publishers.each do |p|
      pub_ids << p.auth
    end

    @archivable_count = Citation.count(
      :all, 
      :conditions => ["publisher_id in (#{pub_ids.join(", ")}) and citation_state_id = 3"]
    )
    return @archivable_count
  end
  
  def add_filter(query, sort, query_filter, facet, value, count)
    # TODO: Add Sort
    # If we have >1 filter, we need to join the facet_field:value
    if query_filter.size > 0 || !query_filter.empty?
      prepped_filter = Array.new
      prepped_filter << query_filter.dup

      if(!query_filter.include?('"' + value.to_s + '"'))
        prepped_filter << '"' + value.to_s + '"'
      end
      
      prepped_filter = prepped_filter.join("+>+")

    # If we have no filters, we need to send the first
    else
      prepped_filter = '"' + value.to_s + '"'
    end
    
    link_to "#{value} (#{count})", {
      :q => query,
      :sort => sort,
      :fq => prepped_filter
    }
  end
  
  def remove_filter(query, sort, query_filter, value)
    # TODO: Add Sort
    
    prepped_filter = Array.new
    prepped_filter = query_filter.dup
    prepped_filter.delete_at(prepped_filter.index(value))
    prepped_filter = prepped_filter.join("+>+")
    
    link_to "#{value}", {
      :q => query,
      :sort => sort,
      :fq => prepped_filter
    }
  end
  
  #Encodes UTF-8 data such that it is valid in HTML
  def encode_for_html(data)
    code = HTMLEntities.new
    code.encode(data, :decimal)
  end
  
  #Encodes UTF-8 data such that it is valid in XML
  def encode_for_xml(data)
    code = HTMLEntities.new
    code.encode(data, :basic)
  end
end
