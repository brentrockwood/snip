%w(rubygems sinatra dm-core dm-timestamps dm-aggregates uri haml).each  { |lib| require lib}

module Snip
  SlugSize = 4
  
  get '/' do
    haml :index
  end

  post '/' do
    original = params[:original]
    original = 'http://' + original unless original[0..3] == 'http'
    uri = URI::parse(original)
    raise "Invalid URL" unless uri.kind_of? URI::HTTP or uri.kind_of? URI::HTTPS

    if params[:slug].nil? || params[:slug].length == 0
      @link = Link.first(:original => uri.to_s)
      
      if @link.nil?
        slug = rand(62**SlugSize).to_s(36)        
        @link = Link.create(:slug => slug, :original => uri.to_s)
      end
        
      return haml :index
    else
      slug = URI::escape params[:slug]

      if Link.count(:slug.eql => slug, :original.not => uri.to_s ) > 0
        raise "A different URL already exists with that name.  Please choose another or leave blank to get a random name."
      end

      @link = Link.first_or_create(:slug => slug, :original => uri.to_s)    
      haml :index
    end
  end

  get '/:slug' do
    link = Link.get(params[:slug])

    if link.nil? : raise Sinatra::NotFound end
    
    redirect link.original, 301
  end
  
  get '/:slug/stats' do
    'This is where the statistics will go.'
  end

  error do
    haml :index
  end

  DataMapper.setup(:default, ENV['DATABASE_URL'] || "sqlite3://#{Dir.pwd}/db/development.db")

  class Link
    include DataMapper::Resource
  
    property :slug,       String,   :length => SlugSize, :key => true
    property :original,   String,   :length => 255
    property :accesses,   Integer,  :default => 0
    property :created_at, DateTime 
  end
  
  #Link.auto_migrate!

  use_in_file_templates!
end
__END__

@@ layout
!!! 1.1
%html
  %head
    %title brentr.ca
    %link{:rel => 'stylesheet', :href => 'http://www.w3.org/StyleSheets/Core/Swiss', :type => 'text/css'}  
  = yield
        
@@ index
%h1.title brentr.ca
%p
  A URL shortener by
  %a{:href => 'http://brentrockwood.com/'}
    Brent Rockwood
  \.
- unless @link.nil?
  %p
    %code
      = @link.original
    shortened to 
    %code
      %a{:href => env['HTTP_REFERER'] + @link.slug}
        = env['HTTP_REFERER'] + @link.slug
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