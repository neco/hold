ENV['RACK_ENV'] = 'test'

require 'hold'
require 'exchanges'

require 'blueprints'
require 'fakeweb'
require 'rack/test'
require 'webrat'

FakeWeb.allow_net_connect = false

Webrat.configure do |config|
  config.mode = :rack
end

Spec::Runner.configure do |config|
  include Rack::Test::Methods
  include Webrat::Methods
  include Webrat::Matchers

  config.before(:each) do
    DataMapper.auto_migrate!
  end

  def app
    Sinatra::Application
  end

  def fakeweb_template(template)
    File.join(File.expand_path(File.dirname(__FILE__)), 'static', template)
  end
end
