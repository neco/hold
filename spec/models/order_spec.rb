require 'spec_helper'

describe Order do
  context "state machine" do
    it "is initialized in state created" do
      Order.new.state.should == 'created'
    end

    it "transitions from created to synced" do
      order = Order.make(:state => 'created')
      order.mark_as_synced
      order.state.should == 'synced'
    end

    it "transitions from created to failed" do
      order = Order.make(:state => 'created')
      order.mark_as_failed
      order.state.should == 'failed'
    end

    it "transitions from synced to on hold" do
      order = Order.make(:state => 'synced')
      order.place_on_hold
      order.state.should == 'on_hold'
    end
  end

  context "#event_name" do
    it "replaces '/' with 'vs.'" do
      order = Order.new(:event => 'New York Knicks/Denver Nuggets')
      order.event_name.should == 'New York Knicks vs. Denver Nuggets'
    end
  end

  context "#sync" do
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

      @order = Order.make
    end

    it "tries to open an SSH tunnel and retry if there's a database error" do
      DBI.should_receive(:connect).once.and_raise(DBI::DatabaseError)
      DBI.should_receive(:connect).once.and_return(@connection)
      @order.should_receive(:system).once.with("ssh -f -N -L 1433:localhost:1433 #{POS[:user]}@#{POS[:host]} -p #{POS[:port]}")
      @order.sync
    end

    it "raises the error if the tunnel is already open and there's an error" do
      DBI.stub(:connect).and_raise(DBI::DatabaseError)
      @order.should_receive(:system).once.with("ssh -f -N -L 1433:localhost:1433 #{POS[:user]}@#{POS[:host]} -p #{POS[:port]}")
      lambda { @order.sync }.should raise_error(DBI::DatabaseError)
    end

    it "raises an error if an SSH tunnel cannot be opened" do
      DBI.should_receive(:connect).once.and_raise(DBI::DatabaseError)
      @order.should_receive(:system).and_raise('error')
      lambda { @order.sync }.should raise_error(RuntimeError)
    end

    it "prepares a query to find the tickets for this order" do
      @connection.should_receive(:prepare).with('EXEC neco_adHocFindTickets ?, ?, ?, ?, ?').and_return(@procedure)
      @order.sync
    end

    it "sets the first parameter of the prepared query to section" do
      @procedure.should_receive(:bind_param).with(1, @order.section, false)
      @order.sync
    end

    it "sets the second parameter of the prepared query to row" do
      @procedure.should_receive(:bind_param).with(2, @order.row, false)
      @order.sync
    end

    it "sets the third parameter of the prepared query to event name" do
      @procedure.should_receive(:bind_param).with(3, @order.event_name, false)
      @order.sync
    end

    it "sets the fourth parameter of the prepared query to occurs at" do
      @procedure.should_receive(:bind_param).with(4, @order.occurs_at.strftime('%m-%d-%Y %H:%M'), false)
      @order.sync
    end

    it "sets the fifth parameter of the prepared query to a wildcard" do
      @procedure.should_receive(:bind_param).with(5, '%', false)
      @order.sync
    end

    it "executes the query" do
      @procedure.should_receive(:execute)
      @order.sync
    end

    it "finishes the query" do
      @procedure.should_receive(:finish)
      @order.sync
    end

    it "creates a new ticket for each ticket result returned" do
      @tickets.each do |ticket|
        @order.tickets.should_receive(:create).with(
          :ticket_id => ticket[0],
          :group_id => ticket[1],
          :section => ticket[2],
          :row => ticket[3],
          :seat => ticket[4],
          :event => ticket[5],
          :venue => ticket[7],
          :city => ticket[8],
          :occurs_at => ticket[6]
        )
      end

      @order.sync
    end

    it "marks the order state as synced if any ticket results are returned" do
      @order.state.should == 'created'
      @order.sync
      @order.state.should == 'synced'
    end

    it "marks the order state as failed if no ticket results are returned" do
      @order.state.should == 'created'
      @procedure.should_receive(:fetch_all).and_return([])
      @order.sync
      @order.state.should == 'failed'
    end
  end
end
