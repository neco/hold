require 'spec_helper'

describe Order do
  before(:each) do
    @pos = POS.new
    POS.stub(:new).and_return(@pos)
  end

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

    it "removes 'Tickets' from the end of the event name" do
      order = Order.new(:event => 'Westminster Kennel Club Dog Show Tickets')
      order.event_name.should == 'Westminster Kennel Club Dog Show'
    end

    it "removes anything following a hypen" do
      order = Order.new(:event => 'Sony Ericsson Open Tickets - Session 13')
      order.event_name.should == 'Sony Ericsson Open'

      order = Order.new(:event => 'In the Heights Tickets - Broadway')
      order.event_name.should == 'In the Heights'

      order = Order.new(:event => 'Houston Rodeo Tickets - Lady Antebellum')
      order.event_name.should == 'Houston Rodeo'
    end

    it "removes anything following in parenthesis" do
      order = Order.new(:event => 'Super Bowl XLIV Tickets (Indianapolis Colts vs New Orleans Saints)')
      order.event_name.should == 'Super Bowl XLIV'
    end

    it "replaces 'at' with 'vs.' and swaps teams" do
      order = Order.new(:event => 'Washington Wizards at New York Knicks Tickets')
      order.event_name.should == 'New York Knicks vs. Washington Wizards'
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

      @pos.stub(:find_tickets).and_return(@tickets)

      @order = Order.make
    end

    it "finds tickets for the order's event, seat, and row" do
      @pos.should_receive(:find_tickets).with(@order.event_name, @order.occurs_at, @order.section, @order.row).and_return(@tickets)
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
      @pos.should_receive(:find_tickets).and_return([])
      @order.sync
      @order.state.should == 'failed'
    end
  end

  context "#hold" do
    before(:each) do
      @order = Order.make(:quantity => 2, :state => 'synced')
    end

    it "use the highest seat numbers in the block first" do
      @order.stub(:tickets).and_return([
        Ticket.make(:ticket_id => 1010, :seat => '10'),
        Ticket.make(:ticket_id => 1011, :seat => '11'),
        Ticket.make(:ticket_id => 1012, :seat => '12')
      ])

      @pos.should_receive(:hold_tickets).with(1011, 1012)

      @order.hold
    end

    it "take the smallest block in the row that won't leave a single ticket" do
      @order.stub(:tickets).and_return([
        Ticket.make(:ticket_id => 1010, :seat => '10'),
        Ticket.make(:ticket_id => 1011, :seat => '11'),
        Ticket.make(:ticket_id => 1012, :seat => '12'),
        # gap
        Ticket.make(:ticket_id => 1014, :seat => '14'),
        Ticket.make(:ticket_id => 1015, :seat => '15'),
        Ticket.make(:ticket_id => 1016, :seat => '16'),
        Ticket.make(:ticket_id => 1017, :seat => '17'),
      ])

      @pos.should_receive(:hold_tickets).with(1016, 1017)

      @order.hold
    end

    it "marks the order state as on hold" do
      @order.stub(:tickets).and_return([
        Ticket.make(:ticket_id => 1010, :seat => '10'),
        Ticket.make(:ticket_id => 1011, :seat => '11')
      ])

      @pos.stub(:hold_tickets)

      @order.state.should == 'synced'
      @order.hold
      @order.state.should == 'on_hold'
    end
  end
end
