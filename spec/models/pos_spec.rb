require 'spec_helper'

describe POS do
  context ".find_tickets" do
    before(:each) do
      ticket = [
        350031,
        '409',
        'G',
        '11',
        'New York Knicks vs. Denver Nuggets',
        DateTime.parse('2010-03-23T19:30:00+00:00'),
        'Madison Square Garden',
        'New York'
      ]

      @tickets = [
        [1462193] + ticket,
        [1462194] + ticket,
      ]

      @procedure = stub('procedure')
      @procedure.stub(:bind_param)
      @procedure.stub(:execute)
      @procedure.stub(:fetch_all).and_return(@tickets)
      @procedure.stub(:finish)

      @connection = stub('POS')
      @connection.stub(:prepare).and_return(@procedure)

      DBI.stub(:connect).and_return(@connection)

      @pos = POS.new
    end

    def find_tickets
      @pos.find_tickets(
        'New York Knicks vs. Denver Nuggets',
        DateTime.parse('2010-03-23T19:30:00+00:00'),
        '409',
        'G'
      )
    end

    it "tries to open an SSH tunnel and retry if there's a database error" do
      DBI.should_receive(:connect).once.and_raise(DBI::DatabaseError)
      DBI.should_receive(:connect).once.and_return(@connection)
      @pos.should_receive(:system).once.with(/ssh -f -N -L 1433:localhost:1433 \w+@[\.a-z]+ -p \d+/)
      find_tickets
    end

    it "raises the error if the tunnel is already open and there's an error" do
      DBI.stub(:connect).and_raise(DBI::DatabaseError)
      @pos.should_receive(:system).once.with(/ssh -f -N -L 1433:localhost:1433 \w+@[\.a-z]+ -p \d+/)
      lambda { find_tickets }.should raise_error(DBI::DatabaseError)
    end

    it "raises an error if an SSH tunnel cannot be opened" do
      DBI.should_receive(:connect).once.and_raise(DBI::DatabaseError)
      @pos.should_receive(:system).and_raise('error')
      lambda { find_tickets }.should raise_error(RuntimeError)
    end

    it "prepares a query to find the tickets for this order" do
      @connection.should_receive(:prepare).with('EXEC neco_adHocFindTickets ?, ?, ?, ?, ?').and_return(@procedure)
      find_tickets
    end

    it "sets the first parameter of the prepared query to section" do
      @procedure.should_receive(:bind_param).with(1, '409', false)
      find_tickets
    end

    it "sets the second parameter of the prepared query to row" do
      @procedure.should_receive(:bind_param).with(2, 'G', false)
      find_tickets
    end

    it "sets the third parameter of the prepared query to event name" do
      @procedure.should_receive(:bind_param).with(3, 'New York Knicks vs. Denver Nuggets', false)
      find_tickets
    end

    it "sets the fourth parameter of the prepared query to occurs at" do
      @procedure.should_receive(:bind_param).with(4, DateTime.parse('2010-03-23T19:30:00+00:00').strftime('%m-%d-%Y %H:%M'), false)
      find_tickets
    end

    it "sets the fifth parameter of the prepared query to a wildcard" do
      @procedure.should_receive(:bind_param).with(5, '%', false)
      find_tickets
    end

    it "executes the query" do
      @procedure.should_receive(:execute)
      find_tickets
    end

    it "finishes the query" do
      @procedure.should_receive(:finish)
      find_tickets
    end
  end
end
