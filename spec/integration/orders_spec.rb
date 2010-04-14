require 'spec_helper'

describe "The orders page" do
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
