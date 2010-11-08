%w(rubygems sinatra dm-core dm-timestamps dm-aggregates uri haml link).each  { |lib| require lib}

module Snip
  SlugSize = 4
  BaseUrl = 'http://brentr.ca/'
  
  # Return the index page - form.
  get '/' do
    haml :index
  end
  
  # TinyURL compatible API endpoint.
  get '/shorten' do
    Link.shorten(params[:original], params[:slug]).short_url
  end

  # HTML shorten endpoint to post form to.
  post '/' do
    @link = Link.shorten(params[:original], params[:slug])

    haml :index
  end

  # Redirects to the target.
  get '/:slug' do
    link = Link.get(params[:slug])

    if link.nil? : raise Sinatra::NotFound end
    
    link.accesses = link.accesses + 1
    link.save
    
    redirect link.original, 301
  end
  
  # Displays access stats for the specified shortened url.
  get '/:slug/stats' do
    @link = Link.get params[:slug]

    if @link.nil? : raise Sinatra::NotFound end
      
    haml :stats 
  end
          
  # Show the index whenever we have an error.
  error do
    haml :index
  end
  
  DataMapper.setup(:default, ENV['DATABASE_URL'] || "sqlite3://#{Dir.pwd}/db/development.db")

  class Link
    include DataMapper::Resource
  
    property :slug,       String,   :length => 255, :key => true
    property :original,   String,   :length => 255
    property :accesses,   Integer,  :default => 0
    property :created_at, DateTime
  
    def short_url
      BaseUrl + slug
    end
            
    # This is the primary method for shortening URL's.  It implements
    # the following logic:
    # * A slug, if already used, cannot be reused for a different URL.
    # * If a shortened URL already exists and a slug has not been provided,
    #   or the slug matches the pre-existing shortened link, the existing
    #   link is returned rather than creating new.
    # * An valid http(s) URL must be provided.
    def self.shorten(original, slug = nil)      
      # Validate the target url.
      begin
        original = 'http://' + original unless original[0..3] == 'http'
        uri = URI::parse(original)
        raise ArgumentError, "Invalid URL" unless uri.kind_of? URI::HTTP or uri.kind_of? URI::HTTPS
      rescue
        raise ArgumentError, "Invalid URL"
      end
       
      if slug.nil? || slug.length == 0
        # No particular slug was requested.  Return any existing
        # link with this target, or return a new, randomly named 
        # link.
        @link = Link.first(:original => uri.to_s)
        
        if @link.nil?
          # Yes, this could collide here.
          slug = rand(36**SlugSize).to_s(36)        
          @link = Link.create(:slug => slug, :original => uri.to_s)
        end
      else
        # A custom slug was requested.  If it exists with this target,
        # return it.  If it exists with a different target, complain.
        # Otherwise, create and return it.
        slug = URI::escape slug

        if Link.count(:slug => slug, :original.not => uri.to_s ) > 0
          raise "A different URL already exists with that name.  Please choose another or leave blank to get a random name."
        end

        @link = Link.first_or_create(:slug => slug, :original => uri.to_s)    
      end
      
      @link
    end
  end

  enable :inline_templates
end
__END__

@@ layout
!!! 1.1
%html
  %head
    %title brentr.ca
    %link{:rel => 'stylesheet', :href => 'http://www.w3.org/StyleSheets/Core/Swiss', :type => 'text/css'}  
  %body
    %h1.title brentr.ca
    %p
      A URL shortener by
      %a{:href => 'http://brentrockwood.com/'}
        Brent Rockwood
      \.
    = yield
        
@@ index
- unless @link.nil?
  %p
    %code
      = @link.original
    has been shortened to 
    %code
      %a{:href => @link.short_url}
        = @link.short_url
  %p
    #err.warning= env['sinatra.error']
  
%form{:method => 'post', :action => '/'}
  %table
    %tr
      %td
        Original URL:
      %td
        %input{:type => 'text', :name => 'original', :size => '50'} 
    %tr
      %td
        Custom name (optional):
      %td
        %input{:type => 'text', :name => 'slug', :size => '50'}
    %tr
      %td/
      %td
        %input{:type => 'submit', :value => 'Shorten'}

@@ stats
%p
  Statistics for
  = @link.short_url
%table
  %tr
    %td
      Original URL:
    %td
      = @link.original
  %tr
    %td
      Number of accesses:
    %td
      = @link.accesses.to_s
  %tr
    %td
      Created on:
    %td
      = @link.created_at.strftime('%Y/%m/%d at %H:%M %Z')
