require 'zip/zip'
require 'zip/zipfilesystem'
require 'sword_1_3_adapter'

class AdminController < ApplicationController
  #Only System Admins can access this controller's methods
  permit "admin of System"

  def index
    @title = t('admin.tasks')
    @tab_name = params[:tab] || "works"
  end

  #Find Works which are marked "Ready to Archive"
  def ready_to_archive
    @works = Work.ready_to_archive
  end


  # Deposit immediately via SWORD
  def deposit_via_sword

    #get our Work
    @work = Work.find(params[:work_id])

    #Generate a SWORD package and deposit it.
    # Receive back a hash of deposit information
    @deposit = Sword_1_3_Adapter.send_sword_package(@work, work_mets(@work))

    #Find ExternalSystem corresponding to local Institutional Repository
    external_system = find_or_create_repository_system

    #Save the URI returned from our SWORD deposit to this repository
    ExternalSystemUri.find_or_create_by_work_id_and_external_system_id_and_uri(
        :work_id => @work.id,
        :external_system_id => external_system.id,
        :uri => @deposit['id'])

    #@TODO - NOT all repositories return a full URI in the @deposit['id'].
    #  In fact, only DSpace seems to do this.  Whereas Fedora & Eprints return
    #  internal identifiers in this field.  Can we translate those internal IDs
    #  into URLs for Fedora/EPrints?

    #Save the date deposited to Works table (this will also change the Archived State)
    @work.archived_at = DateTime.parse(@deposit['updated'])
    @work.save
    respond_to do |format|
      format.html
    end
  end

  def duplicates
    @title = t('admin.duplicates.works')
    # Default the filter to only show works marked as "duplicate"
    filter = [Work.solr_duplicate_filter]
    # Add any param filters
    filter << params[:fq] if params[:fq]
    filter = filter.compact
    filter.flatten!

    # Default SolrRuby params
    @query = "*:*" # Lucene syntax for "find everything"
    @filter = filter.clone
    @filter = @filter.each { |f| f.strip! }
    @sort = params[:sort] || "year"
    @order = params[:order]|| "descending"
    @page = params[:page] || 0
    @facet_count = params[:facet_count] || 50
    @rows = params[:rows] || 10
    @export = params[:export] || ""

    @q, @works, @facets = Index.fetch(@query, @filter, @sort, @order, @page, @facet_count, @rows)
    true
  end

  def update_publishers_from_sherpa
    Publisher.update_sherpa_data
    respond_to do |format|
      flash[:notice] = t('common.admin.flash_update_publishers_successful')
      format.html { redirect_to admin_update_sherpa_data_url }
      format.xml { head :ok }
    end
  rescue Exception => e
    respond_to do |format|
      flash[:notice] = t('common.admin.flash_update_publishers_error', :message => e.message)
      format.html { redirect_to admin_update_sherpa_data_url }
      format.xml { head :error }
    end
  end

  protected

  def find_or_create_repository_system
    ExternalSystem.find_by_base_url($REPOSITORY_BASE_URL) ||
        ExternalSystem.find_by_name(t('personalize.repository_name')) ||
        ExternalSystem.find_or_create_by_name_and_base_url(
            :name => t('personalize.repository_name'),
            :base_url => $REPOSITORY_BASE_URL)
  end

  def work_mets(work)
    render_to_string("works/_package.mets.builder", :locals => {:work => work, :filenames_only => true})
  end

end