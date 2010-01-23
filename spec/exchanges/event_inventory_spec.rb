require 'spec_helper'

describe Exchanges::EventInventory do
  before(:all) do
    FakeWeb.register_uri(
      :get,
      'https://www.eventinventory.com/login/index.cfm',
      :body => fakeweb_template('event_inventory/login.html'),
      :content_type => 'text/html'
    )
    FakeWeb.register_uri(
      :post,
      'https://www.eventinventory.com/login/login.cfm',
      :status => [302, 'Found'],
      :location => 'https://www.eventinventory.com/basic/index.cfm'
    )
    FakeWeb.register_uri(
      :get,
      'https://www.eventinventory.com/basic/index.cfm',
      :body => fakeweb_template('event_inventory/home.html'),
      :content_type => 'text/html'
    )
    FakeWeb.register_uri(
      :get,
      'https://www.eventinventory.com/Basic/SystemOrders/Orders.aspx',
      :body => fakeweb_template('event_inventory/orders.html'),
      :content_type => 'text/html'
    )
  end

  before(:each) do
    FakeWeb.register_uri(
      :post,
      'https://www.eventinventory.com/Basic/SystemOrders/Orders.aspx?cfid=155142802&cftoken=5005bb-0dc319a0-4f2d-4daf-8b0b-a63823161877&cfuser=6984F78C-4C5F-450D-AF23F904C0A05928&RefList=%3frestart%3dyes',
      [
        { :body => fakeweb_template('event_inventory/order_1.html') },
        { :body => fakeweb_template('event_inventory/order_2.html') },
        { :body => fakeweb_template('event_inventory/order_3.html') }
      ]
    )

    @exchange = Exchanges::EventInventory.new('username', 'password')
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
      @orders.length.should == 3
    end

    context "returns orders that" do
      before(:each) do
        @order = @orders.first
      end

      it "have a remote ID" do
        @order.remote_id.should == '23349479'
      end

      it "have an event name" do
        @order.event.should == 'Atlanta Hawks/Oklahoma City Thunder'
      end

      it "have a venue name" do
        @order.venue.should == 'Philips Arena'
      end

      it "have an event date" do
        @order.occurs_at.should == Time.local(2010, 1, 18, 14, 0, 0)
      end

      it "have a section" do
        @order.section.should == '209'
      end

      it "have a row" do
        @order.row.should == 'E'
      end

      it "have a quantity" do
        @order.quantity.should == 4
      end

      it "have a unit price" do
        @order.unit_price.should == BigDecimal.new('15.00')
      end
    end
  end

  after(:all) do
    FakeWeb.clean_registry
  end
end
