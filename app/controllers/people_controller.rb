class PeopleController < ApplicationController
  
  caches_page :index, :list, :show
  
  before_filter :login_required, :only => [ :edit, :update ]
  before_filter :find_person, :only => [:edit, :update, :show]
  
  def index
    redirect_to groups_path
  end

  def show
    
    @people_coauths = Authorship.coauthors_of(@person)
    @group_coauths = Authorship.coauthor_groups(@person)
        
    # Locate associated tags
    @tags = @person.tags(10)
    
    # Got an image for this person?
    if !@person.image_url
      @person.image_url = "/images/question_mark.png"
    end
    
    # Prepare vcard webservice address
    # TODO: Generalize this!
    @vcard = "http://suda.co.uk/projects/X2V/get-vcard.php?uri=http%3A//bibapp.wendtlibrary.org/person/show/#{@person.id.to_s}"
    @rss_feeds = [{
      :controller => "rss",
      :action => "person",
      :id => @person.id
    }]
  end

  def new
    if params[:q]
      @ldap_results = ldap_search(params[:q])
    end
  end
  
  def create
    @person = Person.new(params[:person])
    if @person.save
      flash[:notice] = 'Person was successfully created.'
      redirect_to edit_person_path(@person)
    else
      render :action => 'new'
    end
  end

  def edit
    # Prepare unique college affiliations for vcard
    if !@person.image_url
      @person.image_url = "/images/question_mark.png"
    end
  end

  def update
    if @person.update_attributes(params[:person])
      flash[:notice] = "#{@person.display_name} was successfully updated."
      redirect_to person_path(@person)
    else
      render :action => 'edit'
    end
  end

  def destroy
    @person.destroy
    flash[:notice] = "#{@person.display_name} was deleted."
    redirect_to people_path
  end
  
  private
  def find_person
    @person = Person.find(params[:id])
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
        
        ldap = Net::LDAP.new(:host => config['host'], :port => config['port'].to_i, :base => config['base'])
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
