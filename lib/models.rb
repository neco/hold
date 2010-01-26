require 'dbi'
require 'dm-core'
require 'dm-aggregates'
require 'dm-timestamps'

DataMapper.setup(:default, DATABASE)

class Account
  include DataMapper::Resource

  property :id, Serial
  property :exchange, String, :length => 20, :required => true
  property :username, String, :length => 20, :required => true
  property :password, String, :length => 20, :required => true
  property :created_at, DateTime
  property :updated_at, DateTime

  has n, :orders, :order => [:created_at.desc]

  def sync
    exchange_instance = exchange_model.new(username, password)

    exchange_instance.orders.each do |exchange_order|
      order = Order.first(
        :account_id => id,
        :remote_id => exchange_order.remote_id
      )

      attributes = {
        :account_id => id,
        :remote_id => exchange_order.remote_id,
        :event => exchange_order.event,
        :venue => exchange_order.venue,
        :occurs_at => exchange_order.occurs_at,
        :section => exchange_order.section,
        :row => exchange_order.row,
        :quantity => exchange_order.quantity,
        :unit_price => exchange_order.unit_price
      }

      if order
        order.update(attributes)
      else
        Order.create(attributes)
      end
    end
  end

  def exchange_model
    Exchanges.get(exchange)
  end
end

class Order
  include DataMapper::Resource

  property :id, Serial
  property :account_id, Integer
  property :remote_id, String, :length => 20
  property :event, String, :length => 100, :required => true
  property :venue, String, :length => 100, :required => true
  property :occurs_at, DateTime, :required => true
  property :section, String, :length => 20, :required => true
  property :row, String, :length => 20, :required => true
  property :quantity, Integer, :required => true
  property :unit_price, BigDecimal
  property :placed_at, DateTime
  property :created_at, DateTime
  property :updated_at, DateTime

  belongs_to :account

  def event_name
    name = event.dup
    name.sub!('/', ' vs. ')
    name
  end

  def tickets
    connect_to_pos do |pos|
      procedure = pos.prepare('EXEC neco_adHocFindTickets ?, ?, ?, ?, ?')

      procedure.bind_param(1, section, false)
      procedure.bind_param(2, row, false)
      procedure.bind_param(3, event_name, false)
      procedure.bind_param(4, occurs_at.strftime('%m-%d-%Y %H:%M'), false)
      procedure.bind_param(5, '%', false)

      procedure.execute

      data = procedure.fetch_all

      procedure.finish

      data
    end
  end

  def connect_to_pos 
    connection = begin
      puts "DBI:ODBC:#{POS[:dsn]}, #{POS[:database]}, #{POS[:password]}"
      DBI.connect("DBI:ODBC:#{POS[:dsn]}", POS[:database], POS[:password])
    rescue DBI::DatabaseError
      unless @opened_tunnel
        system "ssh -f -N -L 1433:localhost:1433 #{POS[:user]}@#{POS[:host]} -p #{POS[:port]}"
        @opened_tunnel = true
        retry
      end
    end

    if connection
      yield connection
    else
      raise 'Could not connect to POS'
    end
  end
end
