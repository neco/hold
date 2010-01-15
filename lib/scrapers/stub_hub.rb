module Scrapers
  class StubHub < Base
    HOST = 'https://myaccount.stubhub.com'.freeze

    def orders
      login
      visit "#{HOST}/?gSec=account&action=sell&which_info=salePending"

      rows = (dom / 'table.table_default_table tr')
      rows.shift

      rows.collect do |row|
        cells = (row / 'td').collect { |cell| cell.inner_text }
        event_url = (row / 'a').first[:href]

        total = BigDecimal.new(cells[7].gsub(/[^\d\.]/, ''))
        quantity = cells[5].to_i

        visit event_url
        venue = (dom / 'div.topBody a').first.inner_text.strip.split(/\n/).first

        Order.new(
          cells[8],
          nil,
          (total * BigDecimal.new('0.9')) / quantity,
          cells[1],
          venue,
          Time.parse(cells[2]),
          quantity,
          cells[3],
          cells[4],
          nil
        )
      end
    end

    def login
      visit "#{HOST}/login/Signin"
      fill_in 'loginEmail', :with => @username
      fill_in 'loginPassword', :with => @password
      click_button 'signIn'
    end
    private :login
  end
end
