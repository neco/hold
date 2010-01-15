module Scrapers
  class RazorGator < Base
    HOST = 'https://supplier.razorgator.com'.freeze

    def orders
      login('/sss.aspx')

      response = mechanize.send(
        :fetch_page,
        :uri => 'https://supplier.razorgator.com/services/sss_ajax_service.asmx/GetNotProcessedOrders',
        :verb => :post,
        :params => '{"startIndex":0,"maxCount":10}',
        :headers => { 'Content-Type' => 'application/json; charset=UTF-8' }
      )

      data = JSON.parse(response.body)
      items = data['d']['Items'] || []

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
      visit "#{HOST}/login.aspx#{path ? "?ReturnUrl=#{path}" : nil }"
      fill_in 'SSSLogin_UserName', :with => @username
      fill_in 'SSSLogin_Password', :with => @password
      click_button 'Submit'
    end
    private :login
  end
end

