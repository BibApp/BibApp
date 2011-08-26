# Filters added to this controller apply to all controllers in the application.
# Likewise, all the methods added will be available for all controllers.

class ApplicationController < ActionController::Base
  helper :all # include all helpers, all the time
  helper_method :current_user_session, :current_user, :logged_in?

  # See ActionController::RequestForgeryProtection for details
  protect_from_forgery

  # Find the @saved variable, used to display "add" or "remove" links for saved Works
  before_filter :find_saved

  # Adds a work.id to the session[:saved] array
  def add_to_saved
    if request.env["HTTP_REFERER"].nil?
      redirect_to works_path
    else
      @saved = find_saved
      work = Work.find(params[:id])
      @saved.add_work(work)
      redirect_to :back
    end
  end

  def add_many_to_saved
    @saved = find_saved

    works = Index.fetch_all_ids(params[:query], params[:facets], params[:sort], params[:rows])

    works.each do |work|
      work = Work.find(work)
      @saved.add_work(work)
    end

    redirect_to :back
  end

  # Removes a work.id to the session[:saved] array
  def remove_from_saved
    @saved = find_saved
    @saved.remove_work(params[:id].to_i)
    redirect_to :back
  end

  # Sets the session[:saved] array to nil
  def delete_saved
    session[:saved] = nil
    redirect_to saved_path
  end

  private

  # Loads the current session saved, or starts a new saved
  def find_saved
    @saved = session[:saved] ||= Saved.new
  end

  def search(params)

    # Solr filtering
    # * Start with an empty array
    # * If there are param filters, collect them
    # * If we have a nested object, filter for object's works

    filter = Array.new
    if params[:fq]
      filter = params[:fq].collect
    end

    # Are we showing an object's works?
    if !@current_object.nil?
      facet_field = @current_object.class.to_s.downcase
      # We want to show the citation list results page
      params[:view] = "all"

      # Append @current_object to filters
      filter << "#{facet_field}_id:\"#{@current_object.id}\""
      @title = @current_object.name

    elsif !params[:view].blank? && params[:sort].blank?
      # If showing all works, default sort is "year"
      @sort = "year"

    else
      # Recent additions list sorted by "created_at"
      params[:sort] = "created_at" if params[:sort].blank? || params[:sort]=="created"
    end

    # Make certain filters are uniq before continuing
    filter.uniq!

    # Default SolrRuby params
    @query = params[:q] || "*:*" # Lucene syntax for "find everything"
    @filter = filter
    @sort = params[:sort] || "year"
    @order = params[:order] || "descending"
    @page = params[:page] || 0
    @facet_count = params[:facet_count] # Don't limit facet results
    @rows = params[:rows] || 10
    @export = params[:export] || ""

    @sort += "_sort" unless @sort == "score" || @sort == "created_at"

    # Public resultset... only show "accepted" Works
    @filter << "status:3"

    logger.debug("Search params: #{@query}, #{@filter}, #{@sort}, #{@order}, #{@page}, #{@facet_count}, #{@rows}}")
    @q, @works, @facets = Index.fetch(@query, @filter, @sort, @order, @page, @facet_count, @rows)

    @view = params[:view] || "splash"

    @has_next_page = ((Work.count.to_i - (@page.to_i * @rows.to_i)) > 0)

    # Add Feeds
    if @current_object
      @feeds = [{
          :action => "show",
          :id => @current_object.id,
          :format => "rss"
      }]
    end

    # Enable Citeproc
    if @export && !@export.empty?
      works = Work.order("publication_date desc").find(@works.collect { |c| c['pk_i'] })
      ce = WorkExport.new
      @works = ce.drive_csl(@export, works)
    end

    # Gather Spelling Suggestions
    if !@query.empty?
      @spelling_suggestions = Index.get_spelling_suggestions(@query)

      @spelling_suggestions.each do |suggestion|
        # if suggestion matches query don't suggest...
        if suggestion.downcase == @query.downcase
          @spelling_suggestions.delete(suggestion)
        end
      end
    else
      @spelling_suggestions = ""
    end
  end

  protected

  def current_user_session
    return @current_user_session if defined?(@current_user_session)
    @current_user_session = UserSession.find
  end

  def current_user
    return @current_user if defined?(@current_user)
    @current_user = current_user_session && current_user_session.user
  end

  def logged_in?
    current_user
  end

  def require_user
    unless current_user
      store_location
      flash[:notice] = "You must be logged in to access this page"
      redirect_to new_user_session_url
      return false
    end
  end

  def require_no_user
    if current_user
      store_location
      flash[:notice] = "You must be logged out to access this page"
      redirect_back_or_default root_url
      return false
    end
  end

  def store_location
    session[:return_to] = request.fullpath
  end

  def redirect_back_or_default(default)
    redirect_to(session[:return_to] || default)
    session[:return_to] = nil
  end

  #below are copied from previous AuthenticatedSystem mixin for
  #compatibility
  def authorized?
    logged_in?
  end

  def login_required
    authorized? || access_denied
  end

  def access_denied
    respond_to do |format|
      format.html do
        store_location
        redirect_to new_user_session_path
      end
      format.any do
        request_http_basic_authentication 'Web Password'
      end
    end
  end

end