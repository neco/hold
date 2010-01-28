require 'dbi'
require 'dm-core'
require 'dm-aggregates'
require 'dm-timestamps'
require 'state_machine'

DataMapper.setup(:default, DATABASE)

autoload :Account, 'lib/models/account'
autoload :Order, 'lib/models/order'
autoload :Ticket, 'lib/models/ticket'
autoload :POS, 'lib/models/pos'
