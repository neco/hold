require 'spec_helper'

describe Exchanges::EventInventory do
  before(:all) do
    FakeWeb.register_uri(
      :get,
      'https://www.eventinventory.com/login/login.aspx',
      :body => fakeweb_template('event_inventory/login.html'),
      :content_type => 'text/html'
    )
    FakeWeb.register_uri(
      :post,
      'https://www.eventinventory.com/login/login.aspx',
      :status => [302, 'Found'],
      :location => 'https://www.eventinventory.com/Basic/ChangeClient.aspx?autoForward=1'
    )
    FakeWeb.register_uri(
      :get,
      'https://www.eventinventory.com/Basic/ChangeClient.aspx?autoForward=1',
      :body => fakeweb_template('event_inventory/client.html'),
      :content_type => 'text/html'
    )
    FakeWeb.register_uri(
      :post,
      'https://www.eventinventory.com/Basic/ChangeClient.aspx?autoForward=1',
      :status => [302, 'Found'],
      :location => 'https://www.eventinventory.com/Basic/Index.cfm'
    )
    FakeWeb.register_uri(
      :get,
      'https://www.eventinventory.com/Basic/Index.cfm',
      :body => fakeweb_template('event_inventory/home.html'),
      :content_type => 'text/html'
    )
    FakeWeb.register_uri(
      :get,
      'https://www.eventinventory.com/Basic/SystemOrders/Orders.aspx',
      :body => fakeweb_template('event_inventory/orders.html'),
      :content_type => 'text/html'
    )
    FakeWeb.register_uri(
      :post,
      'https://www.eventinventory.com/Basic/SystemOrders/Orders.aspx',
      :status => [302, 'Found'],
      :location => 'https://www.eventinventory.com/Basic/SystemOrders/Details.aspx?OrderId=5069142'
    )
    FakeWeb.register_uri(
      :get,
      'https://www.eventinventory.com/Basic/SystemOrders/Details.aspx?OrderId=5069142',
      :body => fakeweb_template('event_inventory/order.html'),
      :content_type => 'text/html'
    )
  end

  before(:each) do
    @exchange = Exchanges::EventInventory.new('username', 'password')
  end

  context ".broker_id" do
    it "provides access to the broker ID" do
      Exchanges::EventInventory.broker_id.should == 1276
    end
  end

  context ".service" do
    it "provides access to the service name" do
      Exchanges::EventInventory.service.should == 'Event Inventory'
    end
  end

  context "#orders" do
    before(:each) do
      @orders = @exchange.orders
    end

    it "returns an array" do
      @orders.should be_an(Array)
    end

    it "returns all of the orders" do
      @orders.length.should == 1
    end

    context "returns orders that" do
      before(:each) do
        @order = @orders.first
      end

      it "have a remote ID" do
        @order.remote_id.should == '23620598'
      end

      it "have an event name" do
        @order.event.should == 'New York Yankees/Texas Rangers'
      end

      it "have a venue name" do
        @order.venue.should == 'Yankee Stadium'
      end

      it "have an event date" do
        @order.occurs_at.should == Time.utc(2010, 4, 16, 23, 5, 0)
      end

      it "have a section" do
        @order.section.should == 'BLEACHER 201'
      end

      it "have a row" do
        @order.row.should == '17'
      end

      it "have a quantity" do
        @order.quantity.should == 4
      end

      it "have a unit price" do
        @order.unit_price.should == BigDecimal.new('10.45')
      end
    end
  end

  after(:all) do
    FakeWeb.clean_registry
  end
end
