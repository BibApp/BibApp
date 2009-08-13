# Methods added to this helper will be available to all templates in the application.
module ApplicationHelper
  require 'config/personalize.rb'
  require 'htmlentities' if defined? HTMLEntities
  
  def ajax_checkbox_toggle(model, person, selected, reload=nil)
    person = Person.find(person.id)
    if selected
      js = remote_function(
        :url => {
          :controller => :pen_names,
          :action => :destroy,
          :person_id => person.id, 
          "#{model.class.to_s.tableize.singularize}_id".to_sym => model.id,
          :reload => reload
          },
        :method => :delete
      )
    else
      js = remote_function(
        :url => {
          :controller => :pen_names,
          :action => :create,
          :person_id => person.id, 
          "#{model.class.to_s.tableize.singularize}_id".to_sym => model.id,
          :reload => reload
          },
        :method => :post
      )
    end
    check_box_tag("#{model.class.to_s.tableize.singularize}_#{model.id}_toggle", 1, selected, {:onclick => js})
  end

  def letter_link_for(letters, letter, current, path)
    if path.nil?
      if current == true
        content_tag(:li, (letters.index(letter) ? link_to(letter, {:page=> letter}, :class => "some") : content_tag(:a, letter, :class => 'none')), :class => "current")
      else
        content_tag :li, (letters.index(letter) ? link_to(letter, {:page=> letter}, :class => "some") : content_tag(:a, letter, :class => 'none'))
      end
    else
      if current == true
        content_tag(:li, (letters.index(letter) ? link_to(letter, "#{path[:path]}?page=#{letter}", :class => "some") : content_tag(:a, letter, :class => 'none')), :class => "current")
      else
        content_tag :li, (letters.index(letter) ? link_to(letter, "#{path[:path]}?page=#{letter}", :class => "some") : content_tag(:a, letter, :class => 'none'))
      end
    end
  end
  
  def link_to_related_works(work)
    #link_to "Related Works", search_url(:q => "id:#{work-solr_id}", :qt  => "mlt")
    "Related Works"
  end
  
  def link_to_download_from_archive(work)
    #link_to "Download from #{$REPOSITORY_NAME}"
    "Download from #{$REPOSITORY_NAME}"
  end
  
  def link_to_authors(work)
    links = Array.new

    if work['authors_data'] != nil
      work['authors_data'].first(5).each do |au|
        name, id = NameString.parse_solr_data(au)
        links << link_to("#{name.gsub(",", ", ")}", name_string_path(id), {:class => "name_string"})
      end
    
      if work['authors_data'].size > 5
        links << link_to("more...", work_path(work['pk_i']))
      end
    end

    return links.join(", ")
  end
 
  def link_to_editors(work)
    if work['editors_data'] != nil    
      # If no authors, editors go first
      if work['authors_data'] == nil
        str = ""
      else
        str = "In "
      end

      links = Array.new

      work['editors_data'].first(5).each do |ed|
        name, id = NameString.parse_solr_data(ed)
        links << link_to("#{name.gsub(",", ", ")}", name_string_path(id), {:class => "name_string"})
      end
  
      if work['editors_data'].size > 5
        links << link_to("more...", work_path(work['pk_i']))
      end

      str += links.join(", ")
      str += " (Eds.), "
      return str
    end
  end
  
  def link_to_work_publication(work)
    pub_name, pub_id = Publication.parse_solr_data(work['publication_data'])
    return link_to("#{pub_name}", publication_path(pub_id), {:class => "source"})
  end
  
  def link_to_work_publisher(work)
    pub_name, pub_id = Publisher.parse_solr_data(work['publisher_data'])
    return link_to("#{pub_name}", publisher_path(pub_id), {:class => "source"})
  end

  #Generate a "Find It!" OpenURL link, 
  # based on Work information as received from Solr
  def link_to_findit(work)
    
    #Get our OpenURL information
    link_text, base_url, suffix = find_openurl_info
    
    #Substitute Work title
    suffix = (work['title'].nil?) ? suffix.gsub("[title]", "") : suffix.gsub("[title]", work['title'].gsub(" ", "+"))
    #Substitute Work year
    suffix = (work['year'].nil?) ? suffix.gsub("[year]", "") : suffix.gsub("[year]", work['year'].to_s)
    #Substitute Work issue
    suffix = (work['issue'].nil?) ? suffix.gsub("[issue]", "") : suffix.gsub("[issue]", work['issue'].to_s)
    #Substitute Work volume
    suffix = (work['volume'].nil?) ? suffix.gsub("[vol]", "") : suffix.gsub("[vol]", work['volume'].to_s)
    #Substitute Work start-page
    suffix = (work['start_page'].nil?) ? suffix.gsub("[fst]", "") : suffix.gsub("[fst]", work['start_page'].to_s)
    #Substitute Work ISSN/ISBN
    suffix = (work['issn_isbn'].nil?) ? suffix.gsub("[issn]", "") : suffix.gsub("[issn]", work['issn_isbn'].to_s)

    # Prepare link
    link_to link_text, "#{base_url}?#{suffix}"
  end
  
  def work_details(work)
    str = ""
    str += link_to "#{work.publication.authority.name}", publication_path(work.publication.authority.id) if work.publication.authority != nil && work.publication.authority.name != "Unknown"
    str += " &#149; " if work.publication.authority != nil && work.publication.authority.name != "Unknown"
    str += "#{work.publication_date.year} " if work.publication_date != nil
    str += " #{work.volume}" if work.volume != nil
    str += "(#{work.issue}), " if work.issue != nil && !work.issue.empty?
    str += " pgs."
    str += " #{work.start_page}-" if work.start_page != nil
    str += "#{work.end_page}." if work.end_page != nil
    return str
  end
  
  def link_to_google_book(work)
    if !work.publication.isbns.blank?
      haml_tag :div, {:class => "right"} do
        haml_tag :span, {:title => "ISBN"}
          work.publication.isbns.first[:name]
        haml_tag :span, {:title => "ISBN:#{work.publication.isbns.first[:name]}", :class =>"gbs-thumbnail-large gbs-link-to-preview gbs-link"}
      end      
    elsif !work.publication.issn_isbn.blank?
      haml_tag :div, {:class => "right"} do
        haml_tag :span, {:title => "ISBN"}
          work.publication.issn_isbn
        haml_tag :span, {:title => "ISBN:#{work.publication.issn_isbn.gsub(" ", "")}", :class =>"gbs-thumbnail-large gbs-link-to-preview gbs-link"}
      end
    else
      # Nothing
    end
  end
  
  def link_to_add_to_cart(id)
    link_to "Add to cart", :action => "add_to_cart", :id => id
  end
  
  def link_to_remove_from_cart(id)
    link_to "Remove from cart ", :action => "remove_from_cart", :id => id
  end
  
  def link_to_deletecart
    link_to "Empty cart?", :controller => "sessions", :action => "delete_cart"
  end
  
  def coins(work)
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
  
  # NOT USED BY BIBAPP, by Default
  def archivable_count
    if Publisher.find(:all, :conditions => ["publisher_copy = ?", true]).empty?
      return @archivable_count = 0
    end
    
    archivable_publishers = Publisher.find(
      :all, 
      :select => "pub1.id, pub2.id as auth", 
      :from => "publishers pub1", 
      :joins => "join publishers pub2 on pub1.id = pub2.authority_id", 
      :conditions => ["pub1.publisher_copy = ?", true]
    )

    pub_ids = Array.new
    archivable_publishers.each do |p|
      pub_ids << p.auth
    end

    @archivable_count = Work.accepted.count(
      :all, 
      :conditions => ["publisher_id in (?)", pub_ids.join(", ")]
    )
    return @archivable_count
  end
  
  def add_filter(params, facet, value, count)
    filter = Hash.new
    if params[:fq]
      filter[:fq] = params[:fq].collect
    else
      filter[:fq] = []
    end
    
    filter[:fq] << "#{facet}:\"#{value}\""
    filter[:fq].uniq!
    
    link_to "#{value} (#{count})", params.merge(filter)
  end
  
  def remove_filter(params, facet)
    filter = Hash.new
    if params[:fq]
      filter[:fq] = params[:fq].collect
      filter[:fq].delete(facet)
      filter[:fq].uniq!

      #Split filter into field name and display value (they are separated by a colon)
      field_name, display_value = facet.split(':')
      link_to "#{display_value}", params.merge(filter)
    end
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
  
  #Determines the pretty name of a particular Work Status
  def work_state_name(work_state_id)
    #Load Work States hash from personalize.rb
    return $WORK_STATUS[work_state_id]
  end
  
  #Determines the pretty name of a particular Work Archival Status
  def work_archive_state_name(work_archive_state_id)
    #Load Work States hash from personalize.rb
    return $WORK_ARCHIVE_STATUS[work_archive_state_id]
  end
  
  #Finds the Error message for a *specific field* in a Form
  # This is useful to display the error messages next to the
  # appropriate field in a form.
  # This displays a <div> with the error message right after the field
  # Borrowed from: http://www.sciwerks.com/blog/category/ruby-on-rails/page/2/
  def error_for(object, method = nil, options={})
    if method
      err = instance_variable_get("@#{object}").errors.on(method).to_sentence rescue instance_variable_get("@#{object}").errors.on(method)
    else
      err = @errors["#{object}"] rescue nil
    end 
    options.merge!(:class=>'fieldWithErrors', :id=>"#{[object,method].compact.join('_')}-error", :style=> (err ? "#{options[:style]}" : "#{options[:style]};display: none;"))
    content_tag("p",err || "", options )     
  end

  
  private
  
  #Find information necessary to build our OpenURL query
  #  In particular:
  #    OpenURL link text, base url, and query suffixes
  def find_openurl_info
    # Set the canonical resolver variables (from personalize.rb)
    link_text = $WORK_LINK_TEXT
    base_url = $WORK_BASE_URL
    suffix = $WORK_SUFFIX
=begin
    #If we've already found this info for
    # the current session, return it immediately
    if session[:openurl_info]
      link_text = session[:openurl_link_text] if session[:openurl_link_text]
      base_url = session[:openurl_base_url] if session[:openurl_base_url]
    else 
      # Obtain the client IP Addess
      ip = request.env["HTTP_X_FORWARDED_FOR"]
      logger.debug("Client IP: #{ip}")
  
      # Test UW-Madison 
      #ip = "128.104.198.84"
      
      # Test UIUC 
      #ip = "128.174.36.29"
      
      # Test Iowa
      #ip = "128.255.56.180"
  
      # Initialize ResolverRegistry
      client = ResolverRegistry::Client.new
      
      # @TODO: Can this be improved?
      #
      # Steps for ResolverRegistry results
      # 1) Look up *all* the resolvers held for a university 
      # * Some universities have more than one resolver (Iowa has 4!)
      # * Some resolvers look specific to ILL
      # * Some resolvers are for "Ask a Librarian" type services
      #
      # 2) If there are no results use the personalize.rb defaults
      #
      # 3) Loop through results
      #
      # 4) Choose best resolver option
      # * Best option (at least at UW, UIUC, Iowa) seems to be the resolver without specific metadata_formats
      begin
        institution = client.lookup_all(ip)
        
        # Test the ResolverRegistry results...
        # If the ResolverRegistry returns nil
        if institution.nil?
          # Use the default variables
        # Else loop and choose the "best option" 
        else
          institution.each do |i|
            if i.resolver.metadata_formats.empty?
              base_url = i.resolver.base_url
              link_text = i.resolver.link_text
              session[:openurl_link_text] = link_text
              session[:openurl_base_url] = base_url
            end
          end
        end
      rescue
        #If errors, do nothing - just use the defaults from personalize.rb
      end #end begin
      
      # whether we got results or not, flag that we already tried using OpenURL ResolverRegistry
      session[:openurl_info] = true
    end #end if session[:openurl_info]
=end  
    return link_text, base_url, suffix
  end
end
