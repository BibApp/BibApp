#This is intended as a place for abstracting common things that have to do with
#autocomplete which can then be reincluded into appropriate controllers
module AutocompleteControllerMixin

  protected

  def generic_autocomplete_for_group_name(include_hidden = false)
    group_name = params[:group][:name].downcase

    #search at beginning of name
    beginning_search = group_name + "%"
    #search at beginning of any other words in name
    word_search = "% " + group_name + "%"

    groups = Group.order_by_name.where("LOWER(name) LIKE ? OR LOWER(name) LIKE ?", beginning_search, word_search).limit(8)
    groups = Group.unhidden unless include_hidden

    render :partial => 'autocomplete_list', :locals => {:objects => groups}
  end

end