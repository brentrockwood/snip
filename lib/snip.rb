%w(rubygems sinatra dm-core dm-timestamps dm-aggregates uri haml lib/link).each  { |lib| require lib}

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
end
