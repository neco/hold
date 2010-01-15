module Scrapers
  class EventInventory < Base
    HOST = 'https://www.eventinventory.com'.freeze

    def orders
      fetch_orders

      rows = (dom / 'table#ctl00_ContentPlaceHolder_EIWeb_dgOrders tr')
      rows.shift

      rows.collect do |row|
        cells = (row / 'td').collect { |cell| cell.inner_text }
        order_id = cells[0]

        fetch_order(order_id)
        ticket_price = BigDecimal.new((dom / '#ctl00_ContentPlaceHolder_EIWeb_lblActualPrice').first.inner_text.gsub(/[^\d\.]/, ''))

        Order.new(
          order_id,
          Time.parse(cells[1]),
          ticket_price,
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

    def fetch_orders
      login
      visit "#{HOST}/Basic/SystemOrders/Orders.aspx"
    end
    protected :fetch_orders

    def fetch_order(id)
      fetch_orders

      within("//td[text()=#{id}]/..") do |row|
        row.click_button 'Details'
      end
    end
    protected :fetch_order

    def login
      unless @logged_in
        visit "#{HOST}/login/index.cfm"
        fill_in 'Username', :with => @username
        fill_in 'Password', :with => @password
        click_button ' Enter Control Panel '
        @logged_in = true
      end
    end
    private :login
  end
end
