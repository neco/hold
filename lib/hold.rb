require 'bigdecimal'
require 'rubygems'

gem 'json', '1.1.9'
require 'json'

gem 'webrat', '0.4.5'
require 'webrat'
require 'webrat/mechanize'
require 'webrat/case_insensitive'
require 'webrat/xpath_as_css'

Webrat.configure do |config|
  config.mode = :mechanize
end

require 'scrapers/base'
require 'scrapers/event_inventory'
require 'scrapers/razor_gator'
require 'scrapers/stub_hub'
