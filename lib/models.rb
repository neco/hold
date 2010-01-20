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
end
