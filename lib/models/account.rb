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
