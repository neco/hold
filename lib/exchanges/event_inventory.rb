module Exchanges
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
      get "#{HOST}/Basic/SystemOrders/Orders.aspx"
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
        get("#{HOST}/login/index.cfm")

        page.form_with(:action => '/login/login.cfm') do |form|
          form['Username'] = @username
          form['Password'] = @password
        end.click_button

        @logged_in = true
      end
    end
    private :login
  end
end
