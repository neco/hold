require 'spec_helper'

describe "RazorGator scraper" do
  before(:all) do
    FakeWeb.register_uri(
      :get,
      'https://supplier.razorgator.com/login.aspx?ReturnUrl=/sss.aspx',
      :body => fakeweb_template('razor_gator/login.html')
    )
    FakeWeb.register_uri(
      :post,
      'https://supplier.razorgator.com/login.aspx?ReturnUrl=%2fsss.aspx',
      :status => [302, 'Found'],
      :location => 'https://supplier.razorgator.com/sss.aspx'
    )
    FakeWeb.register_uri(
      :get,
      'https://supplier.razorgator.com/sss.aspx',
      :body => fakeweb_template('razor_gator/orders.html')
    )
    FakeWeb.register_uri(
      :post,
      'https://supplier.razorgator.com/services/sss_ajax_service.asmx/GetNotProcessedOrders',
      :body => fakeweb_template('razor_gator/orders.json')
    )
  end

  before(:each) do
    event_inventory = Scrapers::RazorGator.new('username', 'password')
    @orders = event_inventory.orders
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
      @order.order_id.should == '1304241'
    end

    it "have an order date" do
      @order.order_date.should == Time.local(2009, 3, 27, 12, 42, 23)
    end

    it "have an event name" do
      @order.event.should == 'New York Yankees'
    end

    it "have a venue name" do
      @order.venue.should == 'Yankee Stadium'
    end

    it "have an event date" do
      @order.event_date.should == Time.local(2009, 8, 28, 22, 5, 0)
    end

    it "have a quantity" do
      @order.quantity.should == 2
    end

    it "have a section" do
      @order.section.should == 'Terrace Level 328'
    end

    it "have a row" do
      @order.row.should == '2'
    end

    it "have a status" do
      @order.status.should == 'Not Processed'
    end
  end

  after(:all) do
    FakeWeb.clean_registry
  end
end
