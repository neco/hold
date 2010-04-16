require 'spec_helper'

describe "The orders page" do
  context "with one order" do
    before(:each) do
      @order = Order.make
      visit '/orders'
    end

    it "should exist" do
      last_response.should be_ok
      response_body.should contain('Orders')
    end

    it "should list the most recent orders" do
      response_body.should have_selector('table tbody tr:first') do |row|
        row.should contain(@order.event)
        row.should contain(@order.venue)
        row.should contain(@order.section_number)
        row.should contain(@order.row)
        row.should contain(@order.quantity.to_s)
        row.should contain(@order.remote_id.to_s)
      end
    end
  end

  context "with eleven orders" do
    before(:each) do
      21.times { Order.make }
    end

    context "on the first page" do
      before(:each) do
        visit '/orders'
      end

      it "shows an 'Older' link" do
        response_body.should contain('Older')
      end

      it "doesn't show a 'Newer' link" do
        response_body.should_not contain('Newer')
      end

      it "has an 'Older' link that goes to the second page" do
        response_body.should have_selector('.pagination a.next') do |link|
          link.text.should == 'Older'
          link.attr('href').value.should == '/orders/2'
        end
      end
    end

    context "on the second page" do
      before(:each) do
        visit '/orders/2'
      end

      it "shows a 'Newer' link" do
        response_body.should contain('Newer')
      end

      it "doesn't show an 'Older' link" do
        response_body.should_not contain('Older')
      end

      it "has a 'Newer' link that goes to the first page" do
        response_body.should have_selector('.pagination a.previous') do |link|
          link.text.should == 'Newer'
          link.attr('href').value.should == '/orders/1'
        end
      end
    end
  end
end
