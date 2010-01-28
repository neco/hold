class Order
  include DataMapper::Resource

  property :id, Serial
  property :account_id, Integer, :required => true
  property :remote_id, String, :length => 20, :required => true
  property :event, String, :length => 100, :required => true
  property :venue, String, :length => 100, :required => true
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
    name
  end

  def sync
    connect_to_pos do |pos|
      procedure = pos.prepare('EXEC neco_adHocFindTickets ?, ?, ?, ?, ?')

      procedure.bind_param(1, section, false)
      procedure.bind_param(2, row, false)
      procedure.bind_param(3, event_name, false)
      procedure.bind_param(4, occurs_at.strftime('%m-%d-%Y %H:%M'), false)
      procedure.bind_param(5, '%', false)

      procedure.execute

      data = procedure.fetch_all

      procedure.finish

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
  end

  def hold
    big_enough = ticket_blocks.select { |block| block.length >= quantity }

    sized_up = big_enough.inject({}) do |map, block|
      map[block.length] = block unless map[block.length]
      map
    end

    block = if sized_up[quantity]
      sized_up[quantity]
    elsif sized_up.select { |size, block| size > quantity + 1 }.any?
      sized_up[sized_up.keys.sort.first]
    else
      sized_up[quantity + 1]
    end

    block[0..(quantity - 1)].each(&:hold)
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

  def connect_to_pos(&block)
    connection = begin
      DBI.connect("DBI:ODBC:#{POS[:dsn]}", POS[:database], POS[:password])
    rescue DBI::DatabaseError
      unless @opened_tunnel
        begin
          system "ssh -f -N -L 1433:localhost:1433 #{POS[:user]}@#{POS[:host]} -p #{POS[:port]}"
          @opened_tunnel = true
          retry
        rescue
        end
      else
        raise
      end
    end

    if connection
      yield connection
    else
      raise 'Could not connect to POS'
    end
  end
  private :connect_to_pos
end
