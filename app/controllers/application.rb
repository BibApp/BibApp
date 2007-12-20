# Filters added to this controller will be run for all controllers in the application.
# Likewise, all the methods added will be available for all controllers.
class ApplicationController < ActionController::Base
  include AuthenticatedSystem
  
  def pagination(items, options={})
   page = (options[:page] || 1).to_i
   items_per_page = options[:per_page] || 10
   offset = (page - 1) * items_per_page
  
   @item_pages = Paginator.new(self, items.length, items_per_page, page)
   @items = items[offset..(offset + items_per_page - 1)]
  
   return @item_pages, @items
  end
end