require 'spec_helper'

describe "StubHub scraper" do
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
  end

  before(:each) do
    stub_hub = Scrapers::StubHub.new('username', 'password')
    @orders = stub_hub.orders
  end

  context "order scraping" do
    it "returns an array" do
      @orders.should be_an(Array)
    end

    it "returns all of the orders" do
      @orders.length.should == 1
    end
  end

  context "orders" do
    before(:each) do
      @order = @orders.first
    end

    it "have an order ID" do
      @order.order_id.should == '30374632'
    end

    it "have an order date" do
      @order.order_date.should be_nil
    end

    it "have an event name" do
      @order.event.should == 'Chicago Bulls at Golden State Warriors Tickets'
    end

    it "have a venue name" do
      @order.venue.should be_nil
    end

    it "have an event date" do
      @order.event_date.should == Time.local(2010, 1, 18, 13, 0, 0)
    end

    it "have a quantity" do
      @order.quantity.should == 3
    end

    it "have a section" do
      @order.section.should == '226'
    end

    it "have a row" do
      @order.row.should == '15'
    end

    it "have a status" do
      @order.status.should be_nil
    end
  end

  after(:all) do
    FakeWeb.clean_registry
  end
end
