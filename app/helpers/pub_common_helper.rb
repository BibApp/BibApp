#This isn't a very good name, but I can't think of one.
#This is for helping refactor out commonalities between
#PublishersController and PublicationsController.
module PubCommonHelper
  protected
  def update_multiple_generic(klass)
    with_key_and_path_setup(klass) do |key, path|
      #Only system-wide editors can assign authorities
      permit "editor of Group"

      pub_ids = params[:pub_ids]
      auth_id = params[:auth_id]

      @a_to_z = klass.letters
      @page = params[:page] || @a_to_z[0]

      if params[:cancel]
        session[key] = nil
        flash[:notice] = t('common.pub_common.flash_update_multiple_generic_cancel')
      else
        if auth_id
          klass.update_multiple(pub_ids, auth_id)
          session[key] = nil
        else
          flash[:warning] = t('common.pub_common.flash_update_multiple_generic_not_unique')
        end
      end

      respond_to do |wants|
        wants.html do
          redirect_to(self.send(path, :page => @page))
        end
      end
    end
  end

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
    with_key_and_path_setup(klass) do |key, path|
      @a_to_z = klass.letters
      @page = params[:page] || @a_to_z[0]
      @pas = session[key] || Array.new
      begin
        #allow specific operation by client
        yield
      rescue ActiveRecord::RecordNotFound
        flash[:warning] = t('common.pub_common.flash_operate_on_box_generic')
        redirect_to(self.send(path)) and return
      end
      session[key] = @pas
      redirect_to(self.send(path, :page => @page)) unless request.xhr?
    end
  end

  def with_key_and_path_setup(klass)
    klass_name = klass.to_s.underscore
    key = :"#{klass_name}_auths"
    path = :"authorities_#{klass_name.pluralize}_path"
    yield key, path
  end

end