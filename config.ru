$:.unshift(File.expand_path(File.dirname(__FILE__)))

require 'vendor/gems/environment'
require 'hold'

run Sinatra::Application
