require 'lib/snip'
require 'test/unit'
require 'rack/test'
require 'ruby-debug'
require 'dm-migrations'

set :environment, :test

set :root, Proc.new { File.dirname(__FILE__) + "/.." }
DataMapper.setup(:default, "sqlite3://#{Dir.pwd}/db/test.db")
DataMapper.auto_migrate!

class SnipTests < Test::Unit::TestCase
  include Rack::Test::Methods

  def app
    Sinatra::Application
  end
  
  def test_get_missing
    get '/missing'
    assert last_response.status == 404    
  end

  def test_get_form
    get '/'
    assert last_response.status == 200
    assert last_response.body.include? "form"
  end

  def test_new_no_slug
    post '/', "original" => 'http://foo.com/'
    check_success_create
  end

  # If a link exists, and no slug has been requested, should give back the
  # existing link.
  def test_existing_no_slug
    link = Snip::Link.create(:slug => 'foo', :original => 'http://bar.com/' )
    post '/', "original" => 'http://bar.com/'
    check_success_create
    assert last_response.body.include? Snip::BaseUrl + 'foo'
  end

  def test_new_with_slug
    post '/', "original" => 'http://withslug.com/', "slug" => 'slug'
    check_success_create
    assert last_response.body.include? Snip::BaseUrl + 'slug'
  end
  
  def test_existing_with_slug
    link = Snip::Link.create :slug => 'existing', :original => 'http://existing.com/'
    post '/', 'original' => link.original
    check_success_create
    assert last_response.body.include? link.short_url
  end
  
  # If the user attempts to reuse a slug with a different URL, an error should be raised.
  def test_existing_with_slug_different_uri
    link = Snip::Link.create :slug => 'existing1', :original => 'http://existing.com/1'

    assert_raise RuntimeError do
      post '/', 'original' => 'http://existing.com/2', 'slug' => link.slug
      assert last_response.body.include? 'A different URL already exists'
    end
  end
  
  def test_invalid_uri
    post '/'         
    assert false
    rescue
      assert $!.message.include? "Invalid URL"
  end 
  
  def test_accesses
    link = Snip::Link.create :original => 'http://accesses.com/', :slug => 'accesses'
    get link.short_url
    get link.short_url
    link = Snip::Link.get 'accesses'
    assert link.accesses == 2
  end
  
  def test_stats
    link = Snip::Link.create :original => 'http://stats.com/', :slug => 'stats'
    get link.short_url
    get link.short_url
    get link.short_url + "/stats"
    assert last_response.status == 200
    assert /Number of accesses:\s*<\/td>\s*<td>\s*2/.match last_response.body
  end
  
  def test_tinyurl_endpoint
    get "/shorten?slug=tinyurl&original=tinyurl.com"
    assert last_response.status == 200
    assert last_response.body == Snip::BaseUrl + "tinyurl"
  end
  
  def test_redirect
    get "/shorten?slug=redirect&original=redirect.com"
    get last_response.body
    assert last_response.status == 301
  end
  
private
  def check_success_create
    assert last_response.status == 200
    assert last_response.body.include? 'has been shortened to'
  end
end