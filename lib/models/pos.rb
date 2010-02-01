class POS
  def find_tickets(event_name, occurs_at, section, row)
    execute('neco_adHocFindTickets', 5) do |procedure|
      procedure.bind_param(1, section, false)
      procedure.bind_param(2, row, false)
      procedure.bind_param(3, event_name, false)
      procedure.bind_param(4, occurs_at.strftime('%m-%d-%Y %H:%M'), false)
      procedure.bind_param(5, '%', false)

      procedure.execute
      procedure.fetch_all
    end
  end

  def hold_tickets(first_ticket_id, last_ticket_id, occurs_at)
    expires_date_time = occurs_at + (60 * 60 * 24 * 180)
    sold_price = nil
    client_broker_id = nil
    broker_csrid = nil
    pos_user_id = nil
    notes = nil
    internal_notes = nil
    external_notes = nil
    shipping_notes = nil

    execute('neco_adHocHoldTickets', 11) do |procedure|
      procedure.bind_param(1, first_ticket_id, false)
      procedure.bind_param(2, last_ticket_id, false)
      procedure.bind_param(3, expires_date_time, false)
      procedure.bind_param(4, sold_price, false)
      procedure.bind_param(5, client_broker_id, false)
      procedure.bind_param(6, broker_csrid, false)
      procedure.bind_param(7, pos_user_id, false)
      procedure.bind_param(8, notes, false)
      procedure.bind_param(9, internal_notes, false)
      procedure.bind_param(10, external_notes, false)
      procedure.bind_param(11, shipping_notes, false)

      procedure.execute
    end
  end

  def execute(procedure, parameter_count, &block)
    connect_to_pos do |pos|
      begin
        query = "EXEC #{procedure} #{(['?'] * parameter_count).join(', ')}"
        procedure = pos.prepare(query)
        yield procedure
      ensure
        procedure.finish
      end
    end
  end
  private :execute

  def connect_to_pos(&block)
    yield DBI.connect(*POS_DB.values_at(:dsn, :database, :password))
  rescue DBI::DatabaseError
    unless @opened_tunnel
      begin
        system "ssh -f -N -L 1433:localhost:1433 #{POS_DB[:user]}@#{POS_DB[:host]} -p #{POS_DB[:port]}"
        @opened_tunnel = true
        retry
      rescue
        raise 'Could not open SSH tunnel'
      end
    else
      raise
    end
  end
  private :connect_to_pos
end
