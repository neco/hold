class Order
  include DataMapper::Resource

  property :id, Serial
  property :account_id, Integer, :required => true
  property :remote_id, String, :length => 20, :required => true
  property :event, String, :length => 100, :required => true
  property :venue, String, :length => 100
  property :occurs_at, DateTime, :required => true
  property :section, String, :length => 20, :required => true
  property :row, String, :length => 20, :required => true
  property :quantity, Integer, :required => true
  property :unit_price, BigDecimal
  property :placed_at, DateTime
  property :state, String, :required => true, :default => 'created'
  property :created_at, DateTime
  property :updated_at, DateTime

  belongs_to :account
  has n, :tickets

  state_machine :initial => :created do
    state :created
    state :synced
    state :failed
    state :on_hold

    event(:mark_as_synced) { transition :created => :synced }
    event(:mark_as_failed) { transition :created => :failed }
    event(:place_on_hold) { transition :synced => :on_hold }
  end

  def event_name
    name = event.dup
    name.sub!('/', ' vs. ')
    name.sub!(/\s+-\s+[\w\s]+\Z/, '')
    name.sub!(/\s+\([\w\s]+\)\Z/, '')
    name.sub!(/\s+Tickets\Z/, '')
    name = name.split(/\s+at\s+/).reverse.join(' vs. ') if name =~ /\sat\s/
    name
  end

  def sync
    data = pos.find_tickets(event_name, occurs_at, section, row)

    if data.any?
      data.each do |ticket|
        tickets.create(
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

      mark_as_synced
    else
      mark_as_failed
    end
  end

  def hold
    big_enough = ticket_blocks.select { |block| block.length >= quantity }

    sized_up = big_enough.inject({}) do |map, block|
      map[block.length] = block unless map[block.length]
      map
    end

    block = if sized_up[quantity]
      sized_up[quantity]
    elsif (blocks = sized_up.select { |size, block| size > quantity + 1 }).any?
      sized_up[blocks.first.first]
    else
      sized_up[quantity + 1]
    end

    first, last = block[0..(quantity - 1)].values_at(-1, 0)
    pos.hold_tickets(first.ticket_id, last.ticket_id)
    place_on_hold
  end

  def ticket_blocks
    tickets.sort_by { |t| t.seat.to_i }.reverse.inject([]) do |blocks, ticket|
      if blocks.empty?
        blocks << [ticket]
      else
        block = blocks.last

        if block.last.seat.to_i == ticket.seat.to_i + 1
          block << ticket
        else
          blocks << [ticket]
        end
      end

      blocks
    end
  end
  private :ticket_blocks

  def pos
    @pos ||= POS.new
  end
  private :pos
end
