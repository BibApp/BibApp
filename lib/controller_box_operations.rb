module ControllerBoxOperations
  protected
  def add_to_box_generic(klass)
    operate_on_box_generic(klass) do
      if params[:new_pa]
        pa = klass.find(params[:new_pa])
        @pas << pa.id unless @pas.include?(pa.id)
      end
    end
  end

  def remove_from_box_generic(klass)
    operate_on_box_generic(klass) do
      if params[:rem_pa]
        pa = klass.find(params[:rem_pa])
        @pas.delete(pa.id) if @pas.include?(pa.id)
      end
    end
  end

  def operate_on_box_generic(klass)
    klass_name = klass.to_s.underscore
    key = :"#{klass_name}_auths"
    path = :"authorities_#{klass_name.pluralize}_path"
    @a_to_z = klass.letters
    @page = params[:page] || @a_to_z[0]
    @pas = session[key] || Array.new
    begin
      #allow specific operation by client
      yield
    rescue ActiveRecord::RecordNotFound
      flash[:warning] = "One or more publications could not be found."
      redirect_to(self.send(path)) and return
    end
    session[key] = @pas
    redirect_to(self.send(path, :page => @page)) unless request.xhr?
  end
end