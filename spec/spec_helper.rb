ENV['RACK_ENV'] = 'test'

require 'hold'

require 'blueprints'
require 'fakeweb'
require 'rack/test'
require 'webrat'

FakeWeb.allow_net_connect = false

Webrat.configure do |config|
  config.mode = :rack
end

DataMapper.auto_migrate!

Spec::Runner.configure do |config|
  include Rack::Test::Methods
  include Webrat::Methods
  include Webrat::Matchers

  config.before(:each) do
    repository(:default) do
      transaction = DataMapper::Transaction.new(repository)
      transaction.begin
      repository.adapter.push_transaction(transaction)
    end
  end

  config.after(:each) do
    repository(:default) do
      while repository.adapter.current_transaction
        repository.adapter.current_transaction.rollback
        repository.adapter.pop_transaction
      end
    end
  end

  def app
    Sinatra::Application
  end

  def fakeweb_template(template)
    File.join(File.expand_path(File.dirname(__FILE__)), 'static', template)
  end
end
