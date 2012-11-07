class SearchesController < ApplicationController
  # GET /searches
  # GET /searches.json

  before_filter :authenticate_user!, :only => [:all]

  def index

  end

  def all
    @searches = Search.all

    respond_to do |format|
      format.html # index.html.erb
      format.json { render json: @searches }
    end
  end

  # GET /searches/1
  # GET /searches/1.json
  def show
    require 'open-uri'
    require 'json'

    @search = Search.find(params[:id])

    if @search.year.nil?
      imdb_res = JSON.parse(open("http://www.imdb.com/xml/find?json=1&nr=1&tt=on&q=#{CGI.escape(@search.criteria)}").read)
      @imdb = []
      @imdb = @imdb + imdb_res['title_exact'] unless imdb_res['title_exact'].nil?
      @imdb = @imdb + imdb_res['title_popular'] unless imdb_res['title_popular'].nil?
      @imdb = @imdb + imdb_res['title_substring'] unless imdb_res['title_substring'].nil?
      @imdb = @imdb + imdb_res['title_approx'] unless imdb_res['title_approx'].nil?

      @imdb.each do |peli|
        anio = /\d\d\d\d/.match(peli['title_description'])
        anio = anio.nil? ? 5000 : anio[0].to_i
        peli['anio'] = anio
      end
      @imdb.reject! {|peli| peli['anio'].to_i > Time.now.year }  
      @imdb.sort! {|a,b| b['anio'] <=> a['anio']}
    end

    @result = JSON.parse(open("http://apify.ifc0nfig.com/tpb/search?id=#{CGI.escape(@search.criteria)}+#{@search.year.to_s}").read)

    @result.sort! {|a,b| b['seeders'] <=> a['seeders']}
    @total = @result.size
    @result.reject! {|a| a['seeders'].to_i < 5 }
    @rechazados = @total - @result.size

    respond_to do |format|
      format.html # show.html.erb
      format.json { render json: @search }
    end
  end

  # GET /searches/new
  # GET /searches/new.json
  def new
    @search = Search.new

    respond_to do |format|
      format.html # new.html.erb
      format.json { render json: @search }
    end
  end

  # GET /searches/1/edit
  def edit
    @search = Search.find(params[:id])
  end

  def imdb
    render :text => 'hola'
  end

  # POST /searches
  # POST /searches.json
  def create
    @search = Search.new(params[:search])

    respond_to do |format|
      if @search.save
        format.html { redirect_to @search }
        format.json { render json: @search, status: :created, location: @search }
      else
        format.html { render action: "new" }
        format.json { render json: @search.errors, status: :unprocessable_entity }
      end
    end
  end

  # PUT /searches/1
  # PUT /searches/1.json
  def update
    @search = Search.find(params[:id])

    respond_to do |format|
      if @search.update_attributes(params[:search])
        format.html { redirect_to @search }
        format.json { head :ok }
      else
        format.html { render action: "edit" }
        format.json { render json: @search.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /searches/1
  # DELETE /searches/1.json
  def destroy
    @search = Search.find(params[:id])
    @search.destroy

    respond_to do |format|
      format.html { redirect_to new_searches_path }
      format.json { head :ok }
    end
  end
end
