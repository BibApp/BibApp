class AuthorshipsController < ApplicationController
  # GET /authorships
  # GET /authorships.xml
  def index
    @authorships = Authorship.find(:all)

    respond_to do |format|
      format.html # index.html.erb
      format.xml  { render :xml => @authorships }
    end
  end

  # GET /authorships/1
  # GET /authorships/1.xml
  def show
    @authorship = Authorship.find(params[:id])

    respond_to do |format|
      format.html # show.html.erb
      format.xml  { render :xml => @authorship }
    end
  end

  # GET /authorships/new
  # GET /authorships/new.xml
  def new
    @authorship = Authorship.new

    respond_to do |format|
      format.html # new.html.erb
      format.xml  { render :xml => @authorship }
    end
  end

  # GET /authorships/1/edit
  def edit
    @authorship = Authorship.find(params[:id])
  end

  # POST /authorships
  # POST /authorships.xml
  def create
    @authorship = Authorship.new(params[:authorship])

    respond_to do |format|
      if @authorship.save
        flash[:notice] = 'Authorship was successfully created.'
        format.html { redirect_to(@authorship) }
        format.xml  { render :xml => @authorship, :status => :created, :location => @authorship }
      else
        format.html { render :action => "new" }
        format.xml  { render :xml => @authorship.errors, :status => :unprocessable_entity }
      end
    end
  end

  # PUT /authorships/1
  # PUT /authorships/1.xml
  def update
    @authorship = Authorship.find(params[:id])

    respond_to do |format|
      if @authorship.update_attributes(params[:authorship])
        flash[:notice] = 'Authorship was successfully updated.'
        format.html { redirect_to(@authorship) }
        format.xml  { head :ok }
      else
        format.html { render :action => "edit" }
        format.xml  { render :xml => @authorship.errors, :status => :unprocessable_entity }
      end
    end
  end

  # DELETE /authorships/1
  # DELETE /authorships/1.xml
  def destroy
    @authorship = Authorship.find(params[:id])
    @authorship.destroy

    respond_to do |format|
      format.html { redirect_to(authorships_url) }
      format.xml  { head :ok }
    end
  end
end
