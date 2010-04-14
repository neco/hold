require 'haml'
require 'sass'
require 'sinatra'
require 'tzinfo'

require 'lib/config'
require 'lib/models'
require 'lib/exchanges'

set :haml, { :attr_wrapper => '"' }

helpers do
  def output_time(time, convert_utc_times=false)
    if convert_utc_times && time.utc?
      time = TZInfo::Timezone.get('America/New_York').utc_to_local(time)
    end

    time.strftime('%B %d, %Y at %I:%M %p').gsub(/\s(0)/, ' ')
  end
end

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

get %r{/orders/?(\d+)?} do
  @page = params[:captures].try(:first).try(:to_i) || 1
  offset = (@page - 1) * 10
  @orders = Order.all(:order => [:id.desc], :limit => 10, :offset => offset)
  @orders_count = Order.count
  haml :orders
end

get '/stylesheets/master.css' do
  headers 'Content-Type' => 'text/css; charset=utf-8'
  sass :master
end
