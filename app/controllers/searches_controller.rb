class SearchesController < ApplicationController
  # GET /searches
  # GET /searches.json

  before_filter :authenticate_user!, :only => [:all]


  require 'nokogiri'
  require 'open-uri'  

  def tpb
    #doc = Nokogiri::HTML(open('http://torrentz.eu/88c85b7498240c1ad5285073d63e1c6439764f70')) #no piratas
    #doc = Nokogiri::HTML(open('http://torrentz.eu/a9ac69a718a352dd1f7d8be2a589391585755716')) #imagen
    doc = Nokogiri::HTML(open('http://torrentz.eu/7a3736a3b7db99f57fc0a35fa8270059cdd3b741')) #NO imagen
    #doc = Nokogiri::HTML(open('http://torrentz.eu/81df26d2d217a6135810abbd96ed1787549b1a84')) #Rompe todo
    #doc = Nokogiri::HTML(open('http://torrentz.eu/81df26d2d217a6135810abbd96ed1787549b1a84')) #Rompe todo



    #els = doc.search "span.u [text()*='thepiratebay.se']"   #tpb
    els = doc.search "span.u [text()*='kickasstorrents.se']" #kat
     
    @el = els.first
    #if not @el.nil?
      
    #  url = @el.parent['href']

    #  doc = Nokogiri::HTML(open(url))
    #  @torpicture = doc.css('div.torpicture img').first
    #  @downloadlink = doc.css('div.download a').first
    #  @nopiratebay = false
    #else
    #  @nopiratebay = true
    #end
  end

  def test
    require 'nokogiri'
    require 'open-uri'    

    doc = Nokogiri::HTML(open('http://torrentz.eu/search?f=movie+avengers'))

    torrentz = []
    doc.css('div.results dl').each do |link|    
      torrentz << link
    end

    result = []
    torrentz.each do |r|
      if not r.at_css('a').nil?
        item = {}
        item[:name.to_s] = r.at_css('a').content
        item[:url.to_s] = r.at_css('a')['href']
        item[:size.to_s] = r.at_css('span.s').content
        item[:seeders.to_s] = r.at_css('span.u').content.gsub(/,/, '').to_i
        result << item
      end
    end

    result.sort! {|a,b| b['seeders'] <=> a['seeders']}
    #solo se levantan 20
    result = result[0..19]
    @total = result.size
    result.reject! {|a| a['seeders'].to_i < 5 }
    @result = agregar_magnet_picture(result)
    result.reject! {|a| not a['show']}
    @rechazados = @total - @result.size

  end


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
    @search = Search.find(params[:id])
    @params = params
  end

  def show_ajax
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

    else

      doc = Nokogiri::HTML(open("http://torrentz.eu/search?f=movie+#{CGI.escape(@search.criteria)}+#{@search.year.to_s}"))

      torrentz = []
      doc.css('div.results dl').each do |link|    
        torrentz << link
      end

      #Agrego los de piratebay, que pueden ser mejores
      result = JSON.parse(open("http://apify.ifc0nfig.com/tpb/search?id=#{CGI.escape(@search.criteria)}+#{@search.year.to_s}").read)
      result = result.map do |item|
        item['show'] = true
        item['repo'] = 'tpb'
        item['img_repo'] = 'http://torrentz.eu/img/20.gif'
        item['picture'] = 'http://kastatic.com/images/nocover.png'
        item
      end
    

      torrentz.each do |r|
        if not r.at_css('a').nil?
          item = {}
          item[:name.to_s] = r.at_css('a').content
          item[:url.to_s] = r.at_css('a')['href']
          item[:size.to_s] = r.at_css('span.s').content
          item[:seeders.to_s] = r.at_css('span.u').content.gsub(/,/, '').to_i
          result << item
        end
      end

      result.sort! {|a,b| b['seeders'] <=> a['seeders']}
      #solo se levantan 20
      result = result[0..19]
      @total = result.size
      result.reject! {|a| a['seeders'].to_i < 5 }

      result = result.map do |item|
        item[:filmada.to_s] = es_filmada(item[:name.to_s])
        item
      end

      @result = agregar_magnet_picture(result)
      result.reject! {|a| not a['show']}
      @rechazados = @total - @result.size
    end
    render :layout => false    

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

  private 

  def crawl_tpb(url, link)
    doc = Nokogiri::HTML(open(url))    

    link['magnet'] = doc.css('div.download a').first['href']
    picture = doc.css('div.torpicture img').first
    if not picture.nil?
      link['picture'] = picture['src']
    else 
      link['picture'] = 'http://kastatic.com/images/nocover.png'
    end
  end

  def crawl_kat(url, link)
        doc = Nokogiri::HTML(open(url))    

    link['magnet'] = doc.css('a.magnetlinkButton').first['href']
    picture = doc.css('a.movieCover img').first
    if not picture.nil?
      link['picture'] = picture['src']
    else 
      link['picture'] = 'http://kastatic.com/images/nocover.png'
    end
  end   

  def es_filmada(name)
    filmada = false
    claves = [' CAM ', ' HDCAM ', ' HD CAM ', ' TS ', ' TeleSync ']
    claves.each do |clave|
      filmada = (filmada or name.upcase.include? clave.upcase)
    end
    filmada    
  end

  def agregar_magnet_picture(links)
    require 'nokogiri'
    require 'open-uri'  

    urlbase = 'http://torrentz.eu'
    links.each do |link|
      if (not link['url'].nil?) #ya fue cargado de antes
      url = urlbase + link['url']
      doc = Nokogiri::HTML(open(url))      

      #Busco en piratebay
      els = doc.search  "span.u [text()*='thepiratebay.se']"
      if els.first.nil? 
        #Si no encuentra thepiratebay.se, busca tpb.pirateparty.org.uk
        els = doc.search  "span.u [text()*='tpb.pirateparty.org.uk']"
      end
      @el = els.first     

      if not @el.nil?
        crawl_tpb(@el.parent['href'], link)
        link['show'] = true
        link['repo'] = 'tpb'
        link['img_repo'] = 'http://torrentz.eu/img/20.gif'
      else
        #Busco en kickasstorrents
        els = doc.search  "span.u [text()*='kickasstorrents.com']"
        if els.first.nil? 
          #Si no encuentra kickasstorrents.com, busca kat.ph
          els = doc.search  "span.u [text()*='kat.ph']"
        end
        @el = els.first
        if not @el.nil?
          crawl_kat(@el.parent['href'], link)
          link['show'] = true
          link['repo'] = 'kat'
          link['img_repo'] = 'http://torrentz.eu/img/18.gif'
        else
          link['show'] = false
        end
      end   
      end
    end    
    links
  end  
end
