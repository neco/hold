require 'rubygems'

gem 'webrat', '0.4.5'
require 'webrat'
require 'webrat/mechanize'
require 'webrat/case_insensitive'

Webrat.configure do |config|
  config.mode = :mechanize
end

require 'scrapers/base'
require 'scrapers/event_inventory'
