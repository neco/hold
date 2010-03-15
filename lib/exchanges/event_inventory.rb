module Exchanges
  class EventInventory < Base
    HOST = 'https://www.eventinventory.com'.freeze

    self.broker_id = 1276
    self.employee_id = 1276
    self.service = 'Event Inventory'

    def orders
      fetch_orders

      rows = (dom / 'table#ctl00_ContentPlaceHolder_EIWeb_dgOrders tr')
      rows.shift

      rows.collect do |row|
        cells = (row / 'td').collect { |cell| cell.inner_text }
        order_id = cells[0]

        fetch_order(order_id)
        ticket_price = BigDecimal.new((dom / '#ctl00_ContentPlaceHolder_EIWeb_lblActualPrice2').first.inner_text.gsub(/[^\d\.]/, ''))

        Order.new(
          order_id,
          cells[2],
          cells[3],
          Time.parse(cells[4]),
          cells[6],
          cells[7],
          cells[5].to_i,
          ticket_price
        )
      end
    end

    def fetch_orders
      login
      get("#{HOST}/Basic/SystemOrders/Orders.aspx")
    end
    protected :fetch_orders

    def fetch_order(id)
      fetch_orders
      form = page.forms.first
      input = ((dom / "//td[text()=#{id}]/../td").last / 'input').first[:name]
      button = form.button_with(input)
      submit(form, button)
    end
    protected :fetch_order

    def login
      unless @logged_in
        get("#{HOST}/login/login.aspx")

        page.form_with(:action => 'login.aspx') do |form|
          form['ctl00$ContentPlaceHolder_EIWeb$txtUsername'] = @username
          form['ctl00$ContentPlaceHolder_EIWeb$txtPassword'] = @password
        end.click_button

        @logged_in = true
      end
    end
    private :login
  end
end
