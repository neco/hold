module Exchanges
  autoload :Base, 'lib/exchanges/base'
  autoload :EventInventory, 'lib/exchanges/event_inventory'
  autoload :RazorGator, 'lib/exchanges/razor_gator'
  autoload :StubHub, 'lib/exchanges/stub_hub'

  def self.get(name)
    const_get(name.to_sym)
  end
end
