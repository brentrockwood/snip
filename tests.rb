require 'snip'
require 'rack/test'

class SnipTests < Test::Unit::TestCase
  include Rack::Test::Methods

  def app
    Sinatra::Application
  end

  def new_no_slug
  end
  
  def existing_no_slug
  end
  
  def new_with_slug
  end
  
  def existing_with_slug
  end
  
  def existing_with_slug_different_uri
  end
  
  def get_missing
  end
  
  def get_existing
  end

  def get_form
  end
end