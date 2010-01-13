module Scrapers
  class StubHub < Base
    HOST = 'https://myaccount.stubhub.com'.freeze

    def initialize(username, password)
      @username = username
      @password = password
      super()
    end

    def orders
      login
      visit "#{HOST}/?gSec=account&action=sell&which_info=salePending"

      rows = (dom / 'table.table_default_table tr')
      rows.shift

      rows.collect do |row|
        cells = (row / 'td').collect { |cell| cell.inner_text }

        Order.new(
          cells[8],
          nil,
          cells[1],
          nil,
          Time.parse(cells[2]),
          cells[5].to_i,
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
