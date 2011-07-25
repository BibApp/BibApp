module ControllerBoxOperations
  protected
  def add_to_box_generic(klass)
    with_session_key_and_redirect_path_method_name(klass) do |key, path|
      @a_to_z = klass.letters
      @page = params[:page] || @a_to_z[0]
      #Add new pubs to the list, and to the session var
      @pas = session[key] || Array.new
      if params[:new_pa]
        begin
          pa = klass.find(params[:new_pa])
          @pas << pa.id unless @pas.include?(pa.id)
        rescue ActiveRecord::RecordNotFound
          flash[:warning] = "One or more publications could not be found."
          redirect_to(self.send(path)) and return
        end
      end
      session[key] = @pas
      redirect_to(self.send(path, :page => @page)) unless request.xhr?
    end
  end

  def remove_from_box_generic(klass)
    with_session_key_and_redirect_path_method_name(klass) do |key, path|
      @a_to_z = klass.letters
      @page = params[:page] || @a_to_z[0]
      #Remove pubs from the list
      @pas = session[key] || Array.new
      if params[:rem_pa]
        begin
          pa = klass.find(params[:rem_pa])
          @pas.delete(pa.id) if @pas.include?(pa.id)
        rescue ActiveRecord::RecordNotFound
          flash[:warning] = "One or more publications could not be found."
          redirect_to(self.send(path)) and return
        end
      end
      session[key] = @pas
      redirect_to(self.send(path,:page => @page)) unless request.xhr?
    end
  end

  def with_session_key_and_redirect_path_method_name(klass)
    klass_name = klass.to_s.underscore
    session_key = :"#{klass_name}_auths"
    path_method_name = :"authorities_#{klass_name.pluralize}_path"
    yield session_key, path_method_name
  end

end