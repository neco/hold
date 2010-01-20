configure :development do
  DATABASE = "sqlite3://#{File.join(Dir.pwd, 'tmp', 'db.sqlite3')}".freeze
end

configure :production do
  DATABASE = ENV['DATABASE_URL'].freeze
end
