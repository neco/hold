require 'bigdecimal'
require 'extlib'
require 'json'
require 'mechanize'

module Exchanges
  Order = Struct.new(
    :remote_id,
    :event,
    :venue,
    :occurs_at,
    :section,
    :row,
    :quantity,
    :unit_price
  )

  class Base
    class_inheritable_accessor :broker_id, :employee_id, :service

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
      @agent ||= Mechanize.new do |agent|
        agent.keep_alive = false # workaround for issue with SSL verification
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
