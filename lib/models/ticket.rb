class Ticket
  include DataMapper::Resource

  property :id, Serial
  property :order_id, Integer, :required => true
  property :ticket_id, Integer, :required => true
  property :group_id, Integer, :required => true
  property :event, String, :length => 100, :required => true
  property :venue, String, :length => 100, :required => true
  property :city, String, :length => 100, :required => true
  property :occurs_at, DateTime, :required => true
  property :section, String, :length => 20, :required => true
  property :row, String, :length => 20, :required => true
  property :seat, String, :length => 20, :required => true
  property :created_at, DateTime
  property :updated_at, DateTime

  belongs_to :order
end
