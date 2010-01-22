module Exchanges
  class RazorGator < Base
    HOST = 'https://supplier.razorgator.com'.freeze

    def orders
      login('/sss.aspx')

      @page = agent.send(
        :fetch_page,
        :uri => 'https://supplier.razorgator.com/services/sss_ajax_service.asmx/GetNotProcessedOrders',
        :verb => :post,
        :params => '{"startIndex":0,"maxCount":10}',
        :headers => { 'Content-Type' => 'application/json; charset=UTF-8' }
      )

      items = json['d']['Items'] || []

      items.collect do |item|
        Order.new(
          item['Order_ID'].to_s,
          Time.at(item['OrderItem_Date'].scan(/\d+/).first.to_i / 1000),
          BigDecimal.new(item['WholeSaleCost'].to_s),
          item['EventNameDateTime'].split("\n").first,
          item['Venue_Name'],
          Time.at(item['Event_date_time'].scan(/\d+/).first.to_i / 1000),
          item['Quantity'],
          item['Seating_Section'],
          item['Seating_Row'],
          item['OrderStatusName']
        )
      end
    end

    def login(path=nil)
      unless @logged_in
        get("#{HOST}/login.aspx#{path ? "?ReturnUrl=#{path}" : nil }")

        @page = page.form_with(:name => 'Form2') do |form|
          form['SSSLogin$UserName'] = @username
          form['SSSLogin$Password'] = @password
        end.click_button

        @logged_in = true
      end
    end
    private :login
  end
end

