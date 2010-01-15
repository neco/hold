require 'spec_helper'

describe Exchanges::StubHub do
  before(:all) do
    FakeWeb.register_uri(
      :get,
      'https://myaccount.stubhub.com/login/Signin',
      :body => fakeweb_template('stub_hub/login.html')
    )
    FakeWeb.register_uri(
      :post,
      'https://myaccount.stubhub.com/login/signin.signinform',
      :status => [302, 'Found'],
      :location => 'https://www.stubhub.com/?gSec=account&action=sell&which_info=salePending&'
    )
    FakeWeb.register_uri(
      :get,
      'https://myaccount.stubhub.com/?gSec=account&action=sell&which_info=salePending',
      :status => [302, 'Found'],
      :location => 'https://www.stubhub.com/?gSec=account&action=sell&which_info=salePending&'
    )
    FakeWeb.register_uri(
      :get,
      'https://www.stubhub.com/?gSec=account&action=sell&which_info=salePending&',
      :body => fakeweb_template('stub_hub/orders.html')
    )
    FakeWeb.register_uri(
      :get,
      'https://myaccount.stubhub.com/rock-of-ages-new-york-tickets/rock-of-ages-new-york-1-16-2010-902526/',
      :body => fakeweb_template('stub_hub/event_1.html')
    )
    FakeWeb.register_uri(
      :get,
      'https://myaccount.stubhub.com/wicked-broadway-tickets/wicked-new-york-1-17-2010-823340/',
      :body => fakeweb_template('stub_hub/event_2.html')
    )
    FakeWeb.register_uri(
      :get,
      'https://myaccount.stubhub.com/ultimate-fighting-tickets/ufc-111-3-27-2010-920511/',
      :body => fakeweb_template('stub_hub/event_3.html')
    )
  end

  before(:each) do
    stub_hub = Exchanges::StubHub.new('username', 'password')
    @orders = stub_hub.orders
  end

  context "order scraping" do
    it "returns an array" do
      @orders.should be_an(Array)
    end

    it "returns all of the orders" do
      @orders.length.should == 3
    end
  end

  context "orders" do
    before(:each) do
      @order = @orders.first
    end

    it "have an order ID" do
      @order.order_id.should == '30390265'
    end

    it "have an order date" do
      @order.order_date.should be_nil
    end

    it "have a ticket price" do
      @order.ticket_price.should == BigDecimal.new('250.2')
    end

    it "have an event name" do
      @order.event.should == 'Rock of Ages Tickets - New York'
    end

    it "have a venue name" do
      @order.venue.should == 'Brooks Atkinson Theatre'
    end

    it "have an event date" do
      @order.event_date.should == Time.local(2010, 1, 16, 20, 0, 0)
    end

    it "have a quantity" do
      @order.quantity.should == 2
    end

    it "have a section" do
      @order.section.should == 'ORCH'
    end

    it "have a row" do
      @order.row.should == 'G'
    end

    it "have a status" do
      @order.status.should be_nil
    end
  end

  after(:all) do
    FakeWeb.clean_registry
  end
end
