require 'spec_helper'

describe "The accounts page" do
  before(:each) do
    @account = Account.make
    visit '/accounts'
  end

  it "should exist" do
    last_response.should be_ok
    response_body.should contain('Exchange Accounts')
  end

  it "should list the most recent accounts" do
    response_body.should have_selector('table tbody tr:first') do |row|
      row.should contain(@account.exchange)
      row.should contain(@account.username)
      row.should contain(@account.password)
    end
  end

  it "should have a form for creating a new account" do
    select 'Event Inventory', :from => 'exchange'
    fill_in 'username', :with => 'me'
    fill_in 'password', :with => 'secret'
    click_button 'Add'

    response_body.should have_selector('table tbody tr:first') do |row|
      row.should contain('me')
      row.should contain('secret')
    end
  end
end
