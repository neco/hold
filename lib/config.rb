require 'dbi'
require 'hoptoad_notifier'

POS_DB = {
  :dsn => 'DBI:ODBC:POS',
  :database => 'indux',
  :password => '613TALjmDK',
  :host => 'pos.neco.com',
  :user => 'drewadmin',
  :port => 3341
}

configure :development, :production do
  DATABASE = "sqlite3://#{File.join(Dir.pwd, 'config', 'db.sqlite3')}".freeze
end

configure :test do
  DATABASE = "sqlite3://#{File.join(Dir.pwd, 'config', 'test.sqlite3')}".freeze
end

HoptoadNotifier.configure do |config|
  config.api_key = 'cee2dc897686dd748f59ea4eb41bf9a2'
end
