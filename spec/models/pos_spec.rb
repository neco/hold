require 'spec_helper'

describe POS do
  shared_examples_for "a query method" do
    before(:each) do
      @connection_error = DBI::DatabaseError.new('S1000 (0) [unixODBC][FreeTDS][SQL Server]Unable to connect to data source')
    end

    it "tries to open an SSH tunnel and retry if there's a database error" do
      DBI.should_receive(:connect).once.and_raise(@connection_error)
      DBI.should_receive(:connect).once.and_return(@connection)
      @pos.should_receive(:system).once.with(/ssh -f -N -L 1433:localhost:1433 \w+@[\.a-z]+ -p \d+/)
      execute_query
    end

    it "raises the error if the tunnel is already open and there's an error" do
      DBI.stub(:connect).and_raise(@connection_error)
      @pos.should_receive(:system).once.with(/ssh -f -N -L 1433:localhost:1433 \w+@[\.a-z]+ -p \d+/)
      lambda { execute_query }.should raise_error(DBI::DatabaseError)
    end

    it "raises an error if an SSH tunnel cannot be opened" do
      DBI.should_receive(:connect).once.and_raise(@connection_error)
      @pos.should_receive(:system).and_raise('error')
      lambda { execute_query }.should raise_error(RuntimeError)
    end

    it "finishes the query" do
      @procedure.should_receive(:finish)
      execute_query
    end
  end

  context "#find_tickets" do
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

      @connection = stub('POS Database')
      @connection.stub(:prepare).and_return(@procedure)

      DBI.stub(:connect).and_return(@connection)

      @pos = POS.new
    end

    def execute_query
      @pos.find_tickets(
        'New York Knicks vs. Denver Nuggets',
        DateTime.parse('2010-03-23T19:30:00+00:00'),
        '409',
        'G'
      )
    end

    it_should_behave_like "a query method"

    it "prepares a query to find the tickets for this order" do
      @connection.should_receive(:prepare).with('EXEC neco_adHocFindTickets ?, ?, ?, ?, ?').and_return(@procedure)
      execute_query
    end

    it "sets the first parameter of the prepared query to section" do
      @procedure.should_receive(:bind_param).with(1, '409', false)
      execute_query
    end

    it "sets the second parameter of the prepared query to row" do
      @procedure.should_receive(:bind_param).with(2, 'G', false)
      execute_query
    end

    it "sets the third parameter of the prepared query to event name" do
      @procedure.should_receive(:bind_param).with(3, 'New York Knicks vs. Denver Nuggets', false)
      execute_query
    end

    it "sets the fourth parameter of the prepared query to occurs at" do
      @procedure.should_receive(:bind_param).with(4, DateTime.parse('2010-03-23T19:30:00+00:00').strftime('%m-%d-%Y %H:%M'), false)
      execute_query
    end

    it "sets the fifth parameter of the prepared query to a wildcard" do
      @procedure.should_receive(:bind_param).with(5, '%', false)
      execute_query
    end

    it "executes the query" do
      @procedure.should_receive(:execute)
      execute_query
    end
  end

  context "#hold_tickets" do
    before(:each) do
      @now = DateTime.now
      @order = Order.make(:occurs_at => @now)

      @procedure = stub('procedure')
      @procedure.stub(:bind_param)
      @procedure.stub(:execute)
      @procedure.stub(:finish)

      @connection = stub('POS Database')
      @connection.stub(:prepare).and_return(@procedure)

      DBI.stub(:connect).and_return(@connection)

      @pos = POS.new
    end

    def execute_query
      @pos.hold_tickets(@order, 1462193, 1462194)
    end

    it_should_behave_like "a query method"

    it "prepares a query to find the tickets for this order" do
      @connection.should_receive(:prepare).with('EXEC neco_adHocHoldTickets ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?').and_return(@procedure)
      execute_query
    end

    it "sets the first parameter of the prepared query to the first ticket ID" do
      @procedure.should_receive(:bind_param).with(1, 1462193, false)
      execute_query
    end

    it "sets the second parameter of the prepared query to the last ticket ID" do
      @procedure.should_receive(:bind_param).with(2, 1462194, false)
      execute_query
    end

    it "sets the third parameter of the prepared query to the expiration (180 days from the date of the event)" do
      @procedure.should_receive(:bind_param).with(3, (@now + 180).strftime('%m-%d-%Y %H:%M'), false)
      execute_query
    end

    it "sets the fourth parameter of the prepared query to the sold price" do
      @procedure.should_receive(:bind_param).with(4, @order.unit_price.to_f.to_s, false)
      execute_query
    end

    it "sets the fifth parameter of the prepared query to the client broker ID" do
      @procedure.should_receive(:bind_param).with(5, @order.account.exchange_model.broker_id, false)
      execute_query
    end

    it "sets the sixth parameter of the prepared query to the broker CSRID" do
      @procedure.should_receive(:bind_param).with(6, 0, false)
      execute_query
    end

    it "sets the seventh parameter of the prepared query to the POS user ID" do
      @procedure.should_receive(:bind_param).with(7, POS::USER_ID, false)
      execute_query
    end

    it "sets the eighth parameter of the prepared query to the notes (exchange name and order ID)" do
      @procedure.should_receive(:bind_param).with(8, "#{@order.account.exchange_model.service} - #{@order.remote_id}", false)
      execute_query
    end

    it "sets the ninth parameter of the prepared query to the internal notes" do
      @procedure.should_receive(:bind_param).with(9, nil, false)
      execute_query
    end

    it "sets the tenth parameter of the prepared query to the external notes" do
      @procedure.should_receive(:bind_param).with(10, nil, false)
      execute_query
    end

    it "sets the eleventh parameter of the prepared query to the shipping notes" do
      @procedure.should_receive(:bind_param).with(11, nil, false)
      execute_query
    end

    it "executes the query" do
      @procedure.should_receive(:execute)
      execute_query
    end
  end
end
