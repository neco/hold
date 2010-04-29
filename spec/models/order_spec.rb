require 'spec_helper'

describe Order do
  before(:each) do
    @pos = POS.new
    POS.stub(:new).and_return(@pos)
  end

  context "state machine" do
    it "is initialized in state 'created'" do
      Order.new.state.should == 'created'
    end

    it "transitions from 'created' to 'synced'" do
      order = Order.make(:state => 'created')
      order.mark_as_synced
      order.state.should == 'synced'
    end

    it "transitions from 'created' to 'failed'" do
      order = Order.make(:state => 'created')
      order.mark_as_failed
      order.state.should == 'failed'
    end

    it "transitions from 'synced' to 'on hold'" do
      order = Order.make(:state => 'synced')
      order.place_on_hold
      order.state.should == 'on_hold'
    end

    it "sets a timestamp when transitioning to 'on hold'" do
      now = Time.now
      Time.stub!(:now).and_return(now)

      order = Order.make(:state => 'synced')
      order.place_on_hold
      order.held_at.should == now
    end
  end

  context "#event_name" do
    it "uses 'UFC' for 'Ultimate Fighting Championship'" do
      order = Order.make(:event => 'Ultimate Fighting Championship')
      order.event_name.should == 'UFC'
    end

    it "strips preceding 'The'" do
      order = Order.make(:event => 'The Lion King')
      order.event_name.should == 'Lion King'
    end

    context "for Event Inventory events" do
      before(:each) do
        account = Account.make(:exchange => 'EventInventory')
        @order = Order.make(:account => account)
      end

      it "strips anything following '/'" do
        @order.event = 'Baltimore Orioles/Boston Red Sox'
        @order.event_name.should == 'Baltimore Orioles'
      end
    end

    context "for StubHub events" do
      before(:each) do
        account = Account.make(:exchange => 'StubHub')
        @order = Order.make(:account => account)
      end

      it "removes 'Tickets' from the end of the event name" do
        @order.event = 'Westminster Kennel Club Dog Show Tickets'
        @order.event_name.should == 'Westminster Kennel Club Dog Show'
      end

      it "removes anything following 'Tickets' and a hypen" do
        @order.event = 'Sony Ericsson Open Tickets - Session 13'
        @order.event_name.should == 'Sony Ericsson Open'

        @order.event = 'In the Heights Tickets - Broadway'
        @order.event_name.should == 'In the Heights'

        @order.event = 'Houston Rodeo Tickets - Lady Antebellum'
        @order.event_name.should == 'Houston Rodeo'
      end

      it "keeps everything following a hyphen before 'Tickets'" do
        @order.event = 'The E.N.D. World Tour - Black Eyed Peas Tickets'
        @order.event_name.should == 'Black Eyed Peas'
      end

      it "removes anything following in parenthesis" do
        @order.event = 'Super Bowl XLIV Tickets (Indianapolis Colts vs New Orleans Saints)'
        @order.event_name.should == 'Super Bowl XLIV'

        @order.event = 'Dallas Cowboys at Houston Texans Tickets (Pre-Season)'
        @order.event_name.should == 'Houston Texans vs. Dallas Cowboys'
      end

      it "uses 'WWE' for events starting with 'WWE'" do
        @order.event = 'WWE SmackDown ECW Tickets'
        @order.event_name.should == 'WWE'
      end

      it "uses 'UFC' for specific UCF fights" do
        @order.event = 'UFC 111 Tickets (Georges St-Pierre vs. Dan Hardy)'
        @order.event_name.should == 'UFC'
      end

      it "appends the session number with a wildcard for 'Big East' events" do
        @order.event = 'Big East Basketball Tournament Tickets - Session 3 (Georgetown vs. TBD, Marquette vs. TBD)'
        @order.event_name.should == 'Big East%Session 3'
      end

      it "replaces 'at' with 'vs.' and swaps teams" do
        @order.event = 'Washington Wizards at New York Knicks Tickets'
        @order.event_name.should == 'New York Knicks vs. Washington Wizards'
      end

      it "removes anything after a hyphen" do
        @order.event = 'Vancouver Canucks at Los Angeles Kings - Home Game 1'
        @order.event_name.should == 'Los Angeles Kings vs. Vancouver Canucks'
      end

      it "removes anything before a colon" do
        @order.event = 'NHL Western Conference Quarterfinals Playoff Tickets: Vancouver Canucks at Los Angeles Kings - Home Game 2'
        @order.event_name.should == 'Los Angeles Kings vs. Vancouver Canucks'
      end

      it "strips 'Opening Day'" do
        @order.event = 'Los Angeles Angels at New York Yankees Opening Day Tickets'
        @order.event_name.should == 'New York Yankees vs. Los Angeles Angels'
      end

      it "removes preceding year" do
        @order.event = '2010 US Open Golf Tickets - Saturday Session'
        @order.event_name.should == 'US Open Golf'
      end

      it "replaced 'St' with 'St.'" do
        @order.event = 'St Louis Cardinals at Philadelphia Phillies Tickets'
        @order.event_name.should == 'Philadelphia Phillies vs. St. Louis Cardinals'
      end

      it "removes duplicate 'Tickets'" do
        @order.event = 'Roger Waters Tickets Tickets'
        @order.event_name.should == 'Roger Waters'
      end

      it "uses the featured performer" do
        @order.event = 'The Wall Live Tour featuring Roger Waters Tickets Tickets'
        @order.event_name.should == 'Roger Waters'
      end
    end

    context "for RazorGator events" do
      before(:each) do
        account = Account.make(:exchange => 'RazorGator')
        @order = Order.make(:account => account)
      end

      it "replaces '/' with 'vs.'" do
        @order.event = 'New York Knicks/Denver Nuggets'
        @order.event_name.should == 'New York Knicks vs. Denver Nuggets'
      end

      it "removes duplicate team names for RazorGator" do
        @order.event = 'Dallas Mavericks - Dallas Mavericks / San Antonio Spurs'
        @order.event_name.should == 'Dallas Mavericks vs. San Antonio Spurs'
      end

      it "uses 'Houston Rodeo' for 'Rodeo Houston'" do
        @order.event = 'Rodeo Houston'
        @order.event_name.should == 'Houston Rodeo'
      end
    end
  end

  context "#section_number" do
    it "strips out non-numeric characters" do
      order = Order.new(:section => 'Terrace Level 328')
      order.section_number.should == '328'
    end

    it "passes through the section if there's no numeric portion" do
      order = Order.new(:section => 'ORCH')
      order.section_number.should == 'ORCH'
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
      @pos.should_receive(:find_tickets).with(@order.event_name, @order.occurs_at, @order.section_number, @order.row).and_return(@tickets)
      @order.sync
    end

    context "with tickets found" do
      it "creates a new ticket for each ticket found in the POS" do
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

      it "marks the order state as synced" do
        @order.state.should == 'created'
        @order.sync
        @order.state.should == 'synced'
      end
    end

    context "with no tickets found" do
      it "marks the order state as failed" do
        @order.state.should == 'created'
        @pos.should_receive(:find_tickets).and_raise(POS::TicketsNotFound)
        @order.sync rescue POS::TicketsNotFound
        @order.state.should == 'failed'
      end

      it "raises a TicketsNotFound error" do
        @pos.should_receive(:find_tickets).and_raise(POS::TicketsNotFound)
        lambda { @order.sync }.should raise_error(POS::TicketsNotFound)
      end
    end
  end

  context "#hold" do
    before(:each) do
      @order = Order.make(:quantity => 2, :state => 'synced')
    end

    context "with sufficient quantity" do
      it "use the highest seat numbers in the block first" do
        @order.stub(:tickets).and_return([
          Ticket.make(:ticket_id => 1010, :seat => '10'),
          Ticket.make(:ticket_id => 1011, :seat => '11'),
          Ticket.make(:ticket_id => 1012, :seat => '12')
        ])

        @pos.should_receive(:hold_tickets).with(@order, 1011, 1012)

        @order.hold
      end

      it "take the smallest block that won't leave a single ticket" do
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

        @pos.should_receive(:hold_tickets).with(@order, 1016, 1017)

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

    context "with insufficient quantity" do
      before(:each) do
        @order.stub(:tickets).and_return([
          Ticket.make(:ticket_id => 1010, :seat => '10')
        ])

        @pos.stub(:hold_tickets)
      end

      it "raises InsufficientQuantity error without a big enough block" do
        lambda { @order.hold }.should raise_error(Order::InsufficientQuantity)
      end

      it "marks the order state as not held" do
        @order.state.should == 'synced'
        @order.hold rescue Order::InsufficientQuantity
        @order.state.should == 'not_held'
      end
    end
  end
end
