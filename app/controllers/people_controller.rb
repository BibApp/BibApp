class PeopleController < ApplicationController
  require 'redcloth'
  
  # Require a user be logged in to create / update / destroy
  before_filter :login_required, :only => [ :new, :create, :edit, :update, :destroy ]
  
  # Find the @cart variable, used to display "add" or "remove" links for saved citations
  before_filter :find_cart, :only => [:show]
  
  make_resourceful do 
    build :index, :new, :create, :show, :edit, :update, :destroy

    publish :xml, :json, :yaml, :attributes => [
      :id, :name, :first_name, :middle_name, :last_name, :prefix, :suffix, :phone, :email, :im, :office_address_line_one, :office_address_line_two, :office_city, :office_state, :office_zip, :research_focus,
       {:name_strings => [:id, :name]},
       {:groups => [:id, :name]},
       {:contributorships => [:citation_id]}
    ]

    #Add a response for RSS
    response_for :show do |format| 
      format.rss  #loads show.rss.rxml
      format.html  #loads show.html.haml
    end
      
    before :index do
      # find first letter of last name (in uppercase, for paging mechanism)
      @a_to_z = Person.letters.collect { |d| d.letter.upcase }
      
      if params[:q]
        query = params[:q]
        @current_objects = current_objects
      else
        @page = params[:page] || @a_to_z[0]
        @current_objects = Person.find(
          :all, 
          :conditions => ["upper(last_name) like ?", "#{@page}%"], 
          :order => "upper(last_name), upper(first_name)"
        )
      end
      
      @title = "People"
    end
    
    before :new do
      if params[:q]
        @ldap_results = ldap_search(params[:q])
      end
      @title = "Add a Person"
    end
    
    before :show do
      # Default SolrRuby params
      @query        = @current_object.solr_id
      @filter       = params[:fq] || ""
      @filter_no_strip = params[:fq] || ""
      @filter       = @filter.split("+>+").each{|f| f.strip!}
      @sort         = params[:sort] || "year"
      @sort         = "year" if @sort.empty?
      @page         = params[:page] || 0
      @facet_count  = params[:facet_count] || 50
      @rows         = params[:rows] || 10
      @export       = params[:export] || ""

      @q,@docs,@facets = Index.fetch(@query, @filter, @sort, @page, @facet_count, @rows)

      @citations = Array.new
      @docs.each do |citation, score|
        @citations << citation
      end
      
      if @export && !@export.empty?
        x = CitationExport.new
        @citations = x.drive_csl(@export, @citations)
      end      

      @view = "all"
      @title = @current_object.name
      @research_focus = RedCloth.new(@current_object.research_focus).to_html
      
      @feeds = [{
        :action => "show",
        :id => @current_object.id,
        :format => "rss"
      }]
      
    end
  end

  private
  
  def find_cart
    @cart = session[:cart] ||= Cart.new
  end
  
  def ldap_search(query)
    begin
      require 'rubygems'
      require 'net/ldap'
      config = YAML::load(File.read("#{RAILS_ROOT}/config/ldap.yml"))[RAILS_ENV]
      logger.info "Read LDAP config:"
      config.each do |key, val|
        logger.info "#{key}: #{val}"
      end
    
      query
      if query and !query.empty?
        logger.info "Connecting to #{config['host']}:#{config['port']}"
        logger.info "Base DN: #{config['base']}"
        logger.info "Search query: #{query}"
        
        ldap = Net::LDAP.new(
          :host => config['host'], 
          :port => config['port'].to_i, 
          :base => config['base']
        )
        
        filt = Net::LDAP::Filter.eq("cn", "*#{query}*")
        res = Array.new
        return ldap.search( :filter => filt ).map{|entry| clean_ldap(entry)}
      end
    rescue Exception => e
      logger.debug("LDAP exception: #{e.message}")
      logger.debug(e.backtrace.join("\n"))
    end
    Array.new
  end
  
  def clean_ldap(entry)
    res = Hash.new("")
    entry.each do |key, val|
      res[key] = val[0]
      if [:sn, :givenname].include?(key)
        res[key] = NameCase.new(val[0]).nc!
      end
      if [:title, :o, :postaladdress, :l].include?(key)
        res[key] = res[key].titleize
      end
    end
    return res
  end
end