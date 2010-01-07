require 'spec_helper'

describe "Event Inventory scraper" do
  before(:each) do
    event_inventory = Scrapers::EventInventory.new('username', 'password')
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
      @order.order_id.should == '23305226'
    end

    it "have an order date" do
      @order.order_date.should == Time.local(2010, 1, 7, 10, 44, 0)
    end

    it "have an event name" do
      @order.event.should == 'Super Bowl'
    end

    it "have a venue name" do
      @order.venue.should == 'Dolphin Stadium'
    end

    it "have an event date" do
      @order.event_date.should == Time.local(2010, 2, 7, 0, 0, 0)
    end

    it "have a quantity" do
      @order.quantity.should == 2
    end

    it "have a section" do
      @order.section.should == 'CLUB'
    end

    it "have a row" do
      @order.row.should == 'ENDZONE'
    end

    it "have a status" do
      @order.status.should == 'Pending'
    end
  end
end
