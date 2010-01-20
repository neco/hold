require 'haml'
require 'sass'
require 'sinatra'

require 'lib/config'
require 'lib/models'

set :haml, { :attr_wrapper => '"' }

get '/accounts' do
  @accounts = Account.all
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

get '/stylesheets/master.css' do
  headers 'Content-Type' => 'text/css; charset=utf-8'
  sass :master
end
