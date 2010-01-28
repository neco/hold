class POS
  def find_tickets(event_name, occurs_at, section, row)
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

      data
    end
  end

  def connect_to_pos(&block)
    connection = begin
      DBI.connect("DBI:ODBC:#{POS_DB[:dsn]}", POS_DB[:database], POS_DB[:password])
    rescue DBI::DatabaseError
      unless @opened_tunnel
        begin
          system "ssh -f -N -L 1433:localhost:1433 #{POS_DB[:user]}@#{POS_DB[:host]} -p #{POS_DB[:port]}"
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
