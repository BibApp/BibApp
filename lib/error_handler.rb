class ActionController::Base
  ERROR_404 = [
    "ActiveRecord::RecordNotFound", 
    "ActiveRecord::RecordInvalid", 
    "ActionController::RoutingError", 
    "ActionController::UnknownController", 
    "ActionController::UnknownAction", 
    "ActionController::MethodNotAllowed",
    "ActionView::MissingTemplate"
  ]
  
  def rescue_action_in_public(exception)
    logger.debug "I'm in rescue action with #{exception.class.to_s}"

    if ERROR_404.include?(exception.class.to_s)
      logger.debug "Render a 404 error"
      
      # Default SolrRuby params
      @query        = "*:*" # Lucene syntax for "find everything"
      @filter       = []
      @sort         = "year"
      @order        = "descending"
      @page         = 0
      @facet_count  = 50
      @rows         = 10
      @export       = ""
      
      # Public resultset... only show "accepted" Works
      @filter << "status:3"

      @q,@works,@facets = Index.fetch(@query, @filter, @sort, @order, @page, @facet_count, @rows)

      render :partial => "shared/not_found", :layout => "application", :status => "404"
    else
      logger.debug "Render a 500 error"
      render :partial => "shared/application_error", :layout => "error", :status => "500"
    end             
  end
  
  def log_error(exception)
    logger.debug "I'm in Log Error with #{exception.class.to_s}"
    if not ERROR_404.include?(exception.class.to_s)
      begin
        logger.debug "Sending Error Summary"
        Notifier.deliver_error_summary(
          exception, 
          clean_backtrace(exception), 
          session,
          params
        )
      rescue => e
        logger.error(e)
      end
    end
  end
end