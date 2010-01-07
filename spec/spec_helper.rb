require 'hold'
require 'spec'
require 'spec/autorun'
require 'fakeweb'

def fakeweb_template(template)
  File.join(File.expand_path(File.dirname(__FILE__)), 'html', template)
end

Spec::Runner.configure do |config|
  FakeWeb.allow_net_connect = false

  FakeWeb.register_uri(
    :get,
    'https://www.eventinventory.com/login/index.cfm',
    :body => fakeweb_template('event_inventory/login.html')
  )

  FakeWeb.register_uri(
    :post,
    'https://www.eventinventory.com/login/login.cfm',
    :status => [302, 'Found'], 
    :location => 'https://www.eventinventory.com/basic/index.cfm'
  )

  FakeWeb.register_uri(
    :get,
    'https://www.eventinventory.com/basic/index.cfm',
    :body => fakeweb_template('event_inventory/home.html')
  )

  FakeWeb.register_uri(
    :get,
    'https://www.eventinventory.com/Basic/SystemOrders/Orders.aspx',
    :body => fakeweb_template('event_inventory/orders.html')
  )
end
