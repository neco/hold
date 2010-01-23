require 'machinist/data_mapper'

# Shams

Sham.exchange { %w(EventInventory RazorGator StubHub)[3 * rand] }
Sham.username { |index| "Username #{index}" }
Sham.password { |index| "Password #{index}" }
Sham.event { |index| "Event #{index}" }
Sham.venue { |index| "Venue #{index}" }
Sham.section { |index| "Section #{index}" }
Sham.row { |index| "Row #{index}" }
Sham.quantity { (10 * rand).round }

Sham.datetime {
  year = Date.today.year
  month = (1..12).to_a[12 * rand]
  day = (1..28).to_a[28 * rand]
  hour = (14..22).to_a[9 * rand]
  Time.local(year, month, day, hour)
}


# Blueprints

Account.blueprint do
  exchange
  username
  password
end

Order.blueprint do
  event
  venue
  occurs_at { Sham.datetime }
  section
  row
  quantity
end
