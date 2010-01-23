require 'spec_helper'

describe Account do
  it "provides access to the exchange model" do
    account = Account.make(:exchange => 'EventInventory')
    account.exchange_model.should == Exchanges::EventInventory
  end
end
