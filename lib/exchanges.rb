require 'vendor/gems/environment'

require 'bigdecimal'
require 'json'
require 'webrat'
require 'webrat/mechanize'
require 'webrat/case_insensitive'
require 'webrat/xpath_as_css'

Webrat.configure do |config|
  config.mode = :mechanize
end

require 'exchanges/base'
require 'exchanges/event_inventory'
require 'exchanges/razor_gator'
require 'exchanges/stub_hub'
