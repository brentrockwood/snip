module Snip
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
end
