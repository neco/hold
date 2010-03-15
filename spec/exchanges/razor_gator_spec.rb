require 'spec_helper'

describe Exchanges::RazorGator do
  before(:all) do
    FakeWeb.register_uri(
      :get,
      'https://supplier.razorgator.com/login.aspx?ReturnUrl=/sss.aspx',
      :body => fakeweb_template('razor_gator/login.html'),
      :content_type => 'text/html'
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
      :body => fakeweb_template('razor_gator/orders.html'),
      :content_type => 'text/html'
    )
    FakeWeb.register_uri(
      :post,
      'https://supplier.razorgator.com/services/sss_ajax_service.asmx/GetNotProcessedOrders',
      :body => fakeweb_template('razor_gator/orders.json'),
      :content_type => 'text/html'
    )
  end

  before(:each) do
    @exchange = Exchanges::RazorGator.new('username', 'password')
  end

  context ".broker_id" do
    it "provides access to the broker ID" do
      Exchanges::RazorGator.broker_id.should == 1653
    end
  end

  context ".employee_id" do
    it "provides access to the client broker employee ID" do
      Exchanges::RazorGator.broker_id.should == 1653
    end
  end

  context ".service" do
    it "provides access to the service name" do
      Exchanges::RazorGator.service.should == 'RazorGator'
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
        @order.remote_id.should == '1304241'
      end

      it "have an event name" do
        @order.event.should == 'New York Yankees'
      end

      it "have a venue name" do
        @order.venue.should == 'Yankee Stadium'
      end

      it "have an event date" do
        @order.occurs_at.should == Time.utc(2009, 8, 28, 23, 5, 0)
      end

      it "have a section" do
        @order.section.should == 'Terrace Level 328'
      end

      it "have a row" do
        @order.row.should == '2'
      end

      it "have a quantity" do
        @order.quantity.should == 2
      end

      it "have a unit price" do
        @order.unit_price.should == BigDecimal.new('65.10')
      end
    end
  end

  after(:all) do
    FakeWeb.clean_registry
  end
end
