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

      POS.stub(:find_tickets).and_return(@tickets)

      @order = Order.make
    end

    it "finds tickets for the order's event, seat, and row" do
      POS.should_receive(:find_tickets).with(@order.event_name, @order.occurs_at, @order.section, @order.row).and_return(@tickets)
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
      POS.should_receive(:find_tickets).and_return([])
      @order.sync
      @order.state.should == 'failed'
    end
  end

  context "#hold" do
    it "use the highest seat numbers in the block first" do
      @tickets = [
        Ticket.make(:seat => '10'),
        Ticket.make(:seat => '11'),
        Ticket.make(:seat => '12')
      ]

      @tickets[0].should_not_receive(:hold)
      @tickets[1].should_receive(:hold)
      @tickets[2].should_receive(:hold)

      @order = Order.make(:quantity => 2)
      @order.stub(:tickets).and_return(@tickets)

      @order.hold
    end

    it "take the smallest block in the row that won't leave a single ticket" do
      @tickets = [
        Ticket.make(:seat => '20'),
        Ticket.make(:seat => '19'),
        Ticket.make(:seat => '18'),
        Ticket.make(:seat => '17'),
        # gap
        Ticket.make(:seat => '15'),
        Ticket.make(:seat => '14'),
        Ticket.make(:seat => '13'),
        # gap
        Ticket.make(:seat => '11'),
        Ticket.make(:seat => '10')
      ]

      @tickets[0].should_not_receive(:hold)
      @tickets[1].should_not_receive(:hold)
      @tickets[2].should_not_receive(:hold)
      @tickets[3].should_not_receive(:hold)
      # gap
      @tickets[4].should_not_receive(:hold)
      @tickets[5].should_not_receive(:hold)
      @tickets[6].should_not_receive(:hold)
      # gap
      @tickets[7].should_receive(:hold)
      @tickets[8].should_receive(:hold)

      @order = Order.make(:quantity => 2)
      @order.stub(:tickets).and_return(@tickets)

      @order.hold
    end
  end
end
