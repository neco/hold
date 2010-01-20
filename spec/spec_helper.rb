require 'exchanges'
require 'spec'
require 'spec/autorun'
require 'fakeweb'

Spec::Runner.configure do |config|
  FakeWeb.allow_net_connect = false

  def fakeweb_template(template)
    File.join(File.expand_path(File.dirname(__FILE__)), 'html', template)
  end
end
