module Scrapers
  Order = Struct.new(
    :order_id,
    :order_date,
    :event,
    :venue,
    :event_date,
    :quantity,
    :section,
    :row,
    :status
  )

  class Base < Webrat::MechanizeSession
    SAFARI_4 = 'Mozilla/5.0 (Macintosh; U; Intel Mac OS X 10_6_2; en-us) AppleWebKit/531.21.8 (KHTML, like Gecko) Version/4.0.4 Safari/531.21.10'

    def initialize(username, password)
      @username = username
      @password = password
      super()
      mechanize.user_agent = SAFARI_4
    end
  end
end
