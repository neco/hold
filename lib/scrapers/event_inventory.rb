module Scrapers
  class EventInventory < Base
    HOST = 'https://www.eventinventory.com'.freeze

    def initialize(username, password)
      @username = username
      @password = password
      super()
    end

    def orders(all=false)
      login
      visit "#{HOST}/Basic/SystemOrders/Orders.aspx"

      rows = (dom / 'table#ctl00_ContentPlaceHolder_EIWeb_dgOrders tr')
      rows.shift

      rows.collect do |row|
        cells = (row / 'td').collect { |cell| cell.inner_text }

        Order.new(
          cells[0],
          Time.parse(cells[1]),
          cells[2],
          cells[3],
          Time.parse(cells[4]),
          cells[5].to_i,
          cells[6],
          cells[7],
          cells[8]
        )
      end
    end

    def login
      visit "#{HOST}/login/index.cfm"
      fill_in 'Username', :with => @username
      fill_in 'Password', :with => @password
      click_button ' Enter Control Panel '
    end
    private :login
  end
end
