require 'spec_helper'

describe Account do
  before(:each) do
    @account = Account.make(:exchange => 'EventInventory')
  end

  context "#exchange_model" do
    it "provides access to the exchange model" do
      @account.exchange_model.should == Exchanges::EventInventory
    end
  end

  context "#sync" do
    before(:each) do
      @exchange_order = begin
        order = Order.make_unsaved
        Exchanges::Order.new(
          order.remote_id,
          order.event,
          order.venue,
          order.occurs_at,
          order.section,
          order.row,
          order.quantity,
          order.unit_price
        )
      end

      @exchange = stub('exchange')
      @exchange.stub(:orders).and_return([@exchange_order])

      Exchanges::EventInventory.stub(:new).and_return(@exchange)
    end

    it "instantiates an exchange model with the account credentials" do
      Exchanges::EventInventory.should_receive(:new).with(
        @account.username,
        @account.password
      ).and_return(@exchange)

      @account.sync
    end

    it "fetches orders from the exchanges" do
      @exchange.should_receive(:orders).and_return([@exchange_order])
      @account.sync
    end

    it "creates new orders from the exchange" do
      Order.should_receive(:create).with(
        :account_id => @account.id,
        :remote_id => @exchange_order.remote_id,
        :event => @exchange_order.event,
        :venue => @exchange_order.venue,
        :occurs_at => @exchange_order.occurs_at,
        :section => @exchange_order.section,
        :row => @exchange_order.row,
        :quantity => @exchange_order.quantity,
        :unit_price => @exchange_order.unit_price
      )

      @account.sync
    end

    it "updates existing orders from the exchange" do
      attributes = {
        :account_id => @account.id,
        :remote_id => @exchange_order.remote_id,
        :event => @exchange_order.event,
        :venue => @exchange_order.venue,
        :occurs_at => @exchange_order.occurs_at,
        :section => @exchange_order.section,
        :row => @exchange_order.row,
        :quantity => @exchange_order.quantity,
        :unit_price => @exchange_order.unit_price
      }

      order = Order.create(attributes)

      Order.should_receive(:first).with(
        :account_id => @account.id,
        :remote_id => @exchange_order.remote_id
      ).and_return(order)

      order.should_receive(:update).with(attributes)

      @account.sync
    end
  end
end
