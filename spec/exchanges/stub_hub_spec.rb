require 'spec_helper'

describe Exchanges::StubHub do
  before(:all) do
    FakeWeb.register_uri(
      :get,
      'https://myaccount.stubhub.com/login/Signin',
      :body => fakeweb_template('stub_hub/login.html'),
      :content_type => 'text/html'
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
      :body => fakeweb_template('stub_hub/orders.html'),
      :content_type => 'text/html'
    )
    FakeWeb.register_uri(
      :get,
      'https://www.stubhub.com/rock-of-ages-new-york-tickets/rock-of-ages-new-york-1-16-2010-902526/',
      :body => fakeweb_template('stub_hub/event_1.html'),
      :content_type => 'text/html'
    )
    FakeWeb.register_uri(
      :get,
      'https://www.stubhub.com/wicked-broadway-tickets/wicked-new-york-1-17-2010-823340/',
      :body => fakeweb_template('stub_hub/event_2.html'),
      :content_type => 'text/html'
    )
    FakeWeb.register_uri(
      :get,
      'https://www.stubhub.com/ultimate-fighting-tickets/ufc-111-3-27-2010-920511/',
      :body => fakeweb_template('stub_hub/event_3.html'),
      :content_type => 'text/html'
    )
  end

  before(:each) do
    @exchange = Exchanges::StubHub.new('username', 'password')
  end

  context ".broker_id" do
    it "provides access to the broker ID" do
      Exchanges::StubHub.broker_id.should == 1819
    end
  end

  context ".employee_id" do
    it "provides access to the client broker employee ID" do
      Exchanges::StubHub.broker_id.should == 1819
    end
  end

  context ".service" do
    it "provides access to the service name" do
      Exchanges::StubHub.service.should == 'StubHub'
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
        @order.remote_id.should == '30390265'
      end

      it "have an event name" do
        @order.event.should == 'Rock of Ages Tickets - New York'
      end

      it "have a venue name" do
        @order.venue.should == 'Brooks Atkinson Theatre'
      end

      it "have an event date" do
        @order.occurs_at.should == Time.utc(2010, 1, 17, 1, 0, 0)
      end

      it "have a section" do
        @order.section.should == 'ORCH'
      end

      it "have a row" do
        @order.row.should == 'G'
      end

      it "have a quantity" do
        @order.quantity.should == 2
      end

      it "have a unit price" do
        @order.unit_price.should == BigDecimal.new('243.25')
      end
    end
  end

  after(:all) do
    FakeWeb.clean_registry
  end
end
