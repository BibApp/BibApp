class PeopleController < ApplicationController
  require 'redcloth'
  
  # Require a user be logged in to create / update / destroy
  before_filter :login_required, :only => [ :new, :create, :edit, :update, :destroy ]
  
  make_resourceful do 
    build :index, :new, :create, :show, :edit, :update, :destroy

    publish :xml, :json, :yaml, :attributes => [
      :id, :name, :first_name, :middle_name, :last_name, :prefix, :suffix, :phone, :email, :im, :office_address_line_one, :office_address_line_two, :office_city, :office_state, :office_zip, :research_focus,
       {:name_strings => [:id, :name]},
       {:groups => [:id, :name]},
       {:contributorships => [:work_id]}
    ]

    #Add a response for RSS
    response_for :show do |format| 
      format.html  #loads show.html.haml (HTML needs to be first, so I.E. views it by default)
      format.rss  #loads show.rss.rxml
    end
      
    before :index do
      
      # for groups/people
      if params[:group_id]
        @group = Group.find_by_id(params[:group_id].split("-")[0])

        if params[:q]
          query = params[:q]
          @current_objects = current_objects
        else
          @a_to_z = Array.new
          @group.people.each do |person|
            @a_to_z << person.last_name[0,1].upcase
          end
          @a_to_z = @a_to_z.uniq
          @page = params[:page] || @a_to_z[0]
          @current_objects = @group.people.find(
            :all,
            :conditions => ["upper(last_name) like ?", "#{@page}%"],
            :order => "upper(last_name), upper(first_name)"
          )
        end

        @title = "#{@group.name} - People"
      else
      
        if params[:q]
          query = params[:q]
          @current_objects = current_objects
        else
          @a_to_z = Person.letters.collect { |d| d.letter.upcase }
          @page = params[:page] || @a_to_z[0]
          @current_objects = Person.find(
            :all,
            :conditions => ["upper(last_name) like ?", "#{@page}%"],
            :order => "upper(last_name), upper(first_name)"
          )
        end

        @title = "People"
      end
    end
    
    before :new do
      if params[:q]
        @ldap_results = ldap_search(params[:q])
        if @ldap_results.nil?
          @fail = true
        else
          @ldap_results = @ldap_results.compact
        end
      end
      @title = "Add a Person"
    end
    
    before :show do

      search(params)
      @person = @current_object

      # Collect a list of the person's top-level groups for the tree view
      @top_level_groups = Array.new
      @person.memberships.active.collect{|m| m unless m.group.hide?}.each do |m|
        @top_level_groups << m.group.top_level_parent unless m.nil? or m.group.top_level_parent.hide?
      end
      @top_level_groups.uniq!
    end

  end

  def create

    #Check if user hit cancel button
    if params['cancel']
      #just return back to 'new' page
      respond_to do |format|
        format.html {redirect_to new_person_url}
        format.xml  {head :ok}
      end

    else #Only perform create if 'save' button was pressed

      @person = Person.new(params[:person])
      @dupeperson = Person.find_by_uid(@person.uid)

      if @dupeperson.nil?
        respond_to do |format|
          if @person.save
            flash[:notice] = "Person was successfully created."
            format.html {redirect_to new_person_pen_name_path(@person.id)}
            #TODO: not sure this is right
            format.xml  {head :created, :location => person_url(@person)}
          else
            flash[:warning] = "One or more required fields are missing."
            format.html {render :action => "new"}
            format.xml  {render :xml => @person.errors.to_xml}
          end
        end
      else
        respond_to do |format|
          flash[:error] = "This person already exists in the BibApp system: <a href=""", person_path(@dupeperson.id), """>view their record.</a>"
          format.html {render :action => "new"}
          #TODO: what will the xml response be?
          #format.xml  {render :xml => "error"}
        end
      end
    end
  end

  def update

    @person = Person.find(params[:id])

    #Check if user hit cancel button
    if params['cancel']
      #just return back to 'new' page
      respond_to do |format|
        format.html {redirect_to person_url(@person)}
        format.xml  {head :ok}
      end

    else #Only perform create if 'save' button was pressed

      @person.update_attributes(params[:person])

      respond_to do |format|
        if @person.save
          flash[:notice] = "Personal info was successfully updated."
          format.html {redirect_to new_person_pen_name_path(@person.id)}
          #TODO: not sure this is right
          format.xml  {head :created, :location => person_url(@person)}
        else
          flash[:warning] = "One or more required fields are missing."
          format.html {render :action => "new"}
          format.xml  {render :xml => @person.errors.to_xml}
        end
      end
    end
  end

  def destroy
    permit "admin"

    person = Person.find(params[:id])
    return_path = params[:return_path] || people_url

    person.destroy if person

    respond_to do |format|
      flash[:notice] = "#{person.display_name} was successfully deleted."
      #forward back to path which was specified in params
      format.html {redirect_to return_path }
      format.xml  {head :ok}
    end
  end


  private
  
  def ldap_search(query)
    begin
      require 'rubygems'
      require 'net/ldap'
      config = YAML::load(File.read("#{RAILS_ROOT}/config/ldap.yml"))[RAILS_ENV]

      if config.blank?
        @fail_message = "LDAP is not properly configured"
        return nil
      end

      logger.info "Read LDAP config:"
      config.each do |key, val|
        logger.info "#{key}: #{val}"
      end
    
      query
      if query and !query.empty?
        logger.info "Connecting to #{config['host']}:#{config['port']}"
        logger.info "Base DN: #{config['base']}"
        logger.info "Search query: #{query}"

        if config['username'].blank? or config['password'].blank?
          ldap = Net::LDAP.new(
            :host => config['host'],
            :port => config['port'].to_i,
            :base => config['base']
          )
        else
          ldap = Net::LDAP.new(
            :auth => {
              :method => :simple,
              :username => config['username'],
              :password => config['password']
            },
            :host => config['host'],
            :port => config['port'].to_i,
            :base => config['base'],
            :encryption => :simple_tls
          )
          unless ldap.bind
            @fail_message = "Error authenticating LDAP user."
            return nil
          end
        end

        cn_filt = Net::LDAP::Filter.eq("#{config['cn']}", "*#{query}*")
        uid_filt = Net::LDAP::Filter.eq("#{config['uid']}", "*#{query}*")
        mail_filt = Net::LDAP::Filter.eq("#{config['mail']}", "*#{query}*")
        ldap_result = ldap.search( :filter => cn_filt | uid_filt | mail_filt ).map{|entry| clean_ldap(entry)}

        return ldap_result
      end

    rescue Exception => e
      if ldap.get_operation_result.code != 0
        if ldap.get_operation_result.code == 4
          @fail_message = "too many results"
        else
          @fail_message = ldap.get_operation_result.message
        end
        logger.debug("LDAP exception: #{ldap.get_operation_result.message}")
        logger.debug(e.backtrace.join("\n"))
      else 
        @fail_message = e.message
        logger.debug("LDAP exception: #{e.message}")
        logger.debug(e.backtrace.join("\n"))
      end
    end
    nil
  end
  
  def clean_ldap(entry)
    res = Hash.new("")

    config = YAML::load(File.read("#{RAILS_ROOT}/config/ldap.yml"))[RAILS_ENV]

    entry.each do |key, val|
      #res[key] = val[0]

      # map university-specific values
      if config.has_value? key.to_s
        k = config.index(key.to_s).to_sym
        res[k] = val[0]
        res[k] = NameCase.new(val[0]).nc! if [:sn, :givenname, :middlename, :generationqualifier, :displayname].include?(k)
        res[k] = val[0].titleize if [:title, :ou, :postaladdress].include?(k)
      end

    end
    return res
  end

end