require 'faker'
require 'machinist/data_mapper'


# Shams

Sham.integer { (1_000_000 * rand).round }
Sham.username { |index| "Username #{index}" }
Sham.password { |index| "Password #{index}" }
Sham.event { |index| "Event #{index}" }
Sham.venue { |index| "Venue #{index}" }
Sham.city { Faker::Address.city }
Sham.section { |index| "Section #{index}" }
Sham.row { |index| "Row #{index}" }
Sham.seat { |index| "Seat #{index}" }

Sham.datetime {
  year = Date.today.year
  month = (1..12).to_a[12 * rand]
  day = (1..28).to_a[28 * rand]
  hour = (14..22).to_a[9 * rand]
  Time.utc(year, month, day, hour)
}


# Blueprints

Account.blueprint do
  exchange { %w(EventInventory RazorGator StubHub)[3 * rand] }
  username
  password
end

Order.blueprint do
  account
  remote_id { Sham.integer }
  event
  venue
  occurs_at { Sham.datetime }
  section
  row
  quantity { Sham.integer }
end

Ticket.blueprint do
  order
  ticket_id { Sham.integer }
  group_id { Sham.integer }
  section
  row
  seat
  event
  venue
  city
  occurs_at { Sham.datetime }
end
