require 'spec_helper'

context Exchanges do
  context ".get" do
    it "fetches the Event Inventory exchange based on its name" do
      Exchanges.get('EventInventory').should == Exchanges::EventInventory
    end

    it "fetches the RazorGator exchange based on its name" do
      Exchanges.get('RazorGator').should == Exchanges::RazorGator
    end

    it "fetches the StubHub exchange based on its name" do
      Exchanges.get('StubHub').should == Exchanges::StubHub
    end
  end
end
