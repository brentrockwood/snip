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
