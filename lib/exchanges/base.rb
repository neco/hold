require 'bigdecimal'
require 'json'
require 'mechanize'

module Exchanges
  Order = Struct.new(
    :order_id,
    :order_date,
    :ticket_price,
    :event,
    :venue,
    :event_date,
    :quantity,
    :section,
    :row,
    :status
  )

  class Base
    attr_reader :page

    def initialize(username, password)
      @username = username
      @password = password
    end

    def get(url)
      @page = agent.get(url)
    end
    protected :get

    def submit(form, button)
      @page = agent.submit(form, button)
    end
    protected :submit

    def agent
      @agent ||= WWW::Mechanize.new do |agent|
        agent.user_agent_alias = 'Mac Safari'
      end
    end
    protected :agent

    def dom
      Nokogiri.parse(@page.body)
    end
    protected :dom

    def json
      JSON.parse(@page.body)
    end
    protected :json
  end
end
