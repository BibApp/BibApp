require 'author_batch_load'
require 'bibapp_ldap'

class PeopleController < ApplicationController
  require 'redcloth'

  # Require a user be logged in to create / update / destroy
  before_filter :login_required, :only => [:new, :create, :edit, :update, :destroy, :batch_csv_show, :batch_csv_create]

  make_resourceful do
    build :index, :new, :create, :show, :edit, :update, :destroy

    publish :xml, :json, :yaml, :attributes => [
        :id, :name, :first_name, :middle_name, :last_name, :prefix, :suffix, :phone, :email, :im, :office_address_line_one, :office_address_line_two, :office_city, :office_state, :office_zip, :research_focus, :active,
        {:name_strings => [:id, :name]},
        {:groups => [:id, :name]},
        {:contributorships => [:work_id]}]

    #Add a response for RSS
    response_for :show do |format|
      format.html #loads show.html.haml (HTML needs to be first, so I.E. views it by default)
      format.rss #loads show.rss.rxml
      format.rdf
    end

    response_for :index do |format|
      format.html
      format.rdf
    end

    response_for :destroy do |format|
      format.html { redirect_to @return_path }
      format.xml { head :ok }
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
            @a_to_z << person.last_name[0, 1].upcase
          end
          @a_to_z = @a_to_z.uniq
          @page = params[:page] || @a_to_z[0]
          @current_objects = @group.people.where("upper(last_name) like ?", "#{@page}%").order("upper(last_name), upper(first_name)")
        end

        @title = "#{@group.name} - People"
      else

        if params[:q]
          query = params[:q]
          @current_objects = current_objects
        else
          @a_to_z = Person.letters
          @page = params[:page] || @a_to_z[0]
          @current_objects = Person.where("upper(last_name) like ?", "#{@page}%").
              order("upper(last_name), upper(first_name)").includes(:contributorships => :work)
        end

        @title = "People"
      end
    end

    before :new do
      if params[:q]
        begin
          @ldap_results = BibappLdap.instance.search(params[:q])
        rescue BibappLdapConfigError
          @fail_message = "LDAP is not properly configured"
        rescue BibappLdapConnectionError
          @fail_message = "Error authenticating LDAP user."
        rescue BibappLdapTooManyResultsError
          @fail_message = "Too many LDAP results"
        rescue BibappLdapError => e
          @fail_message = e.message
        end
        if @ldap_results.nil?
          @fail = true
        else
          @ldap_results.compact!
        end
      end
      @title = "Add a Person"
    end

    before :show do

      search(params)
      @person = @current_object
      work_count = @q.data['response']['numFound']

      #generate the google chart URI
      #see http://code.google.com/apis/chart/docs/making_charts.html
      #
      if work_count > 0
        chd = "chd=t:"
        chl = "chl="
        chdl = "chdl="
        chdlp = "chdlp=b|"
        @facets[:types].each_with_index do |r, i|
          perc = (r.value.to_f/work_count.to_f*100).round.to_s
          chd += "#{perc},"
          ref = r.name.to_s == 'BookWhole' ? 'Book' : r.name.to_s
          chl += "#{ref.titleize.pluralize}|"
          chdl += "#{perc}% #{ref.titleize.pluralize}|"
          chdlp += "#{i.to_s},"
        end
        chd = chd[0...(chd.length-1)]
        chl = chl[0...(chl.length-1)]
        chdl = chdl[0...(chdl.length-1)]
        chdlp = chdlp[0...(chdlp.length-1)]
        @chart_url = "http://chart.apis.google.com/chart?cht=p&chco=346090&chs=350x100&#{chd}&#{chl}"

        #generate normalized keyword list
        unless @facets[:keywords].blank?
          max = 10
          bin_count = 5
          kwords = @facets[:keywords].first(max)
          max_kw_freq = kwords[0].value.to_i > bin_count ? kwords[0].value.to_i : bin_count

          @keywords = kwords.map { |kw|
            bin = ((kw.value.to_f * bin_count.to_f)/max_kw_freq).ceil
            s = Struct.new(:name, :count)
            s.new(kw.name, bin)
          }.sort { |a, b| a.name <=> b.name }
        end
      end

      # Collect a list of the person's top-level groups for the tree view
      @top_level_groups = Array.new
      @person.memberships.active.collect { |m| m unless m.group.hide? }.each do |m|
        @top_level_groups << m.group.top_level_parent unless m.nil? or m.group.top_level_parent.hide?
      end
      @top_level_groups.uniq!

    end

    before :destroy do
      permit "admin"
      person = Person.find(params[:id])
      @return_path = params[:return_path] || people_url
      person.destroy if person
      #flash[:notice] = "#{person.display_name} was successfully deleted."
    end

  end

  def create

    #Check if user hit cancel button
    if params['cancel']
      #just return back to 'new' page
      respond_to do |format|
        format.html { redirect_to new_person_url }
        format.xml { head :ok }
      end

    else #Only perform create if 'save' button was pressed

      @person = Person.new(params[:person])
      @dupeperson = Person.find_by_uid(@person.uid)

      if @dupeperson.nil?
        respond_to do |format|
          if @person.save
            flash[:notice] = "Person was successfully created."
            format.html { redirect_to new_person_pen_name_path(@person.id) }
            #TODO: not sure this is right
            format.xml { head :created, :location => person_url(@person) }
          else
            flash[:warning] = "One or more required fields are missing."
            format.html { render :action => "new" }
            format.xml { render :xml => @person.errors.to_xml }
          end
        end
      else
        respond_to do |format|
          flash[:error] = "This person already exists in the BibApp system: <a href=" "", person_path(@dupeperson.id), "" ">view their record.</a>"
          format.html { render :action => "new" }
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
        format.html { redirect_to person_url(@person) }
        format.xml { head :ok }
      end

    else #Only perform create if 'save' button was pressed

      @person.update_attributes(params[:person])

      respond_to do |format|
        if @person.save
          flash[:notice] = "Personal info was successfully updated."
          format.html { redirect_to new_person_pen_name_path(@person.id) }
          #TODO: not sure this is right
          format.xml { head :created, :location => person_url(@person) }
        else
          flash[:warning] = "One or more required fields are missing."
          format.html { render :action => "new" }
          format.xml { render :xml => @person.errors.to_xml }
        end
      end
    end
  end

  def load_reftype_chart
    @person = Person.find(params[:person_id])

    #generate the google chart URI
    #see http://code.google.com/apis/chart/docs/making_charts.html
    #
    chd = "chd=t:"
    chl = "chl="
    chdl = "chdl="
    chdlp = "chdlp=b|"
    @person.publication_reftypes.each_with_index do |r, i|
      perc = (r.count.to_f/@person.works.size.to_f*100).round.to_s
      chd += "#{perc},"
      ref = r[:type].to_s == 'BookWhole' ? 'Book' : r[:type].to_s
      chl += "#{ref.titleize.pluralize}|"
      chdl += "#{perc}% #{ref.titleize.pluralize}|"
      chdlp += "#{i.to_s},"
    end
    chd = chd[0...(chd.length-1)]
    chl = chl[0...(chl.length-1)]
    chdl = chdl[0...(chdl.length-1)]
    chdlp = chdlp[0...(chdlp.length-1)]
    @chart_url = "http://chart.apis.google.com/chart?cht=p&chco=346090&chs=350x100&#{chd}&#{chl}"

    render :update do |page|
      page.replace_html "loading_reftype_chart", "<img src='#{@chart_url}' alt='work-type chart' style='margin-left: -50px;margin-bottom:20px;' />"
    end

  end

  def load_keyword_cloud
    #get keywords for the tag cloud
    @person = Person.find(params[:person_id])
    @keywords = @person.keywords(10)

    render :update do |page|
      page.replace_html "loading_keyword_cloud", :partial => "shared/keyword_cloud", :locals => {:keywords => @keywords, :current_object => @person}
    end
  end

  def batch_csv_show
    permit "admin"
  end

  def batch_csv_create
    permit "admin"
    begin
      msg = ''
      data = params[:person][:import_file]
      filename = params[:person][:import_file].original_filename

      str = ''
      if data.respond_to?(:read)
        str = data.read
      elsif File.readable?(data)
        str = File.read(data)
      else
        msg = 'The File you submitted could not be read.'
      end
      if msg.empty?
        unless str.is_utf8?
          encoding = CMess::GuessEncoding::Automatic.guess(str)
          unless encoding.nil? or encoding.empty? or encoding==CMess::GuessEncoding::Encoding::UNKNOWN
            str =Iconv.iconv('UTF-8', encoding, str).to_s
          else
            logger.error("The character encoding could not be determined or could not be converted to UTF-8.\n")
            flash[:notice] = "The character encoding could not be determined or could not be converted to UTF-8."
            msg = 'The file could not be converted to UTF8.'
          end
        end
        if msg.empty?
          # is it better to pass the filename instead of storing the csv contents in the db
          # even if the db row is temporary ?
          Delayed::Job.enqueue CsvPeopleUpload.new(str, current_user.id, filename)
          msg = "Your file was accepted for processing. An email will notify you when the job is completed."
        end
      end
    rescue Exception => e
      flash[:notice] = "Exception: #{e.to_s}"
      msg = 'An error was generated processing your request.'
    end
    redirect_to batch_csv_show_people_url(:completed => msg)
  end

end
