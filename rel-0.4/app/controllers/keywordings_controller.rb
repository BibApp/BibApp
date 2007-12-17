class KeywordingsController < ApplicationController
  # GET /keywordings
  # GET /keywordings.xml
  def index
    @keywordings = Keywording.find(:all)

    respond_to do |format|
      format.html # index.html.erb
      format.xml  { render :xml => @keywordings }
    end
  end

  # GET /keywordings/1
  # GET /keywordings/1.xml
  def show
    @keywording = Keywording.find(params[:id])

    respond_to do |format|
      format.html # show.html.erb
      format.xml  { render :xml => @keywording }
    end
  end

  # GET /keywordings/new
  # GET /keywordings/new.xml
  def new
    @keywording = Keywording.new

    respond_to do |format|
      format.html # new.html.erb
      format.xml  { render :xml => @keywording }
    end
  end

  # GET /keywordings/1/edit
  def edit
    @keywording = Keywording.find(params[:id])
  end

  # POST /keywordings
  # POST /keywordings.xml
  def create
    @keywording = Keywording.new(params[:keywording])

    respond_to do |format|
      if @keywording.save
        flash[:notice] = 'Keywording was successfully created.'
        format.html { redirect_to(@keywording) }
        format.xml  { render :xml => @keywording, :status => :created, :location => @keywording }
      else
        format.html { render :action => "new" }
        format.xml  { render :xml => @keywording.errors, :status => :unprocessable_entity }
      end
    end
  end

  # PUT /keywordings/1
  # PUT /keywordings/1.xml
  def update
    @keywording = Keywording.find(params[:id])

    respond_to do |format|
      if @keywording.update_attributes(params[:keywording])
        flash[:notice] = 'Keywording was successfully updated.'
        format.html { redirect_to(@keywording) }
        format.xml  { head :ok }
      else
        format.html { render :action => "edit" }
        format.xml  { render :xml => @keywording.errors, :status => :unprocessable_entity }
      end
    end
  end

  # DELETE /keywordings/1
  # DELETE /keywordings/1.xml
  def destroy
    @keywording = Keywording.find(params[:id])
    @keywording.destroy

    respond_to do |format|
      format.html { redirect_to(keywordings_url) }
      format.xml  { head :ok }
    end
  end
end
