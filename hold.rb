require 'haml'
require 'sass'
require 'sinatra'

require 'lib/config'
require 'lib/models'
require 'lib/exchanges'

set :haml, { :attr_wrapper => '"' }

get '/accounts' do
  @accounts = Account.all(:order => [:id.desc])
  haml :accounts
end

post '/accounts' do
  @account = Account.create(
    :exchange => params[:exchange],
    :username => params[:username],
    :password => params[:password]
  )

  redirect '/accounts'
end

get '/orders' do
  @orders = Order.all(:order => [:id.desc])
  haml :orders
end

get '/stylesheets/master.css' do
  headers 'Content-Type' => 'text/css; charset=utf-8'
  sass :master
end
