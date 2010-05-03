module Exchanges
  class StubHub < Base
    HOST = 'https://myaccount.stubhub.com'.freeze
    RATE = 0.125.freeze

    self.broker_id = 1819
    self.employee_id = 1819
    self.service = 'StubHub'

    def orders
      login
      get("#{HOST}/?gSec=account&action=sell&which_info=salePending")

      rows = (dom / 'table.table_default_table tr')
      rows.shift

      rows.collect do |row|
        cells = (row / 'td').collect { |cell| cell.inner_text }
        event_url = (row / 'a').first[:href]

        total = BigDecimal.new(cells[7].gsub(/[^\d\.]/, ''))
        quantity = cells[5].to_i

        get(event_url)

        venue = if node = (dom / 'div.topBody a').first
          node.inner_text.strip.split(/\n/).first
        elsif node = (dom / 'span.venue').first
          node['title']
        end

        Order.new(
          cells[8],
          cells[1],
          venue,
          Time.parse(cells[2]),
          cells[3],
          cells[4],
          quantity,
          (total * BigDecimal.new((1 - RATE).to_s)) / quantity
        )
      end
    end

    def login
      unless @logged_in
        get("#{HOST}/login/Signin")

        @page = page.form_with(:name => 'signinForm') do |form|
          form['loginEmail'] = @username
          form['loginPassword'] = @password
        end.click_button

        @logged_in = true
      end
    end
    private :login
  end
end
