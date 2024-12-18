require 'sqlite3'

DB_FILE = File.expand_path('../storage.db', __dir__)

if File.exist?(DB_FILE)
  puts "Database already exists: #{DB_FILE}. Skipping setup."
else
  db = SQLite3::Database.new(DB_FILE)
  db.execute <<-SQL
    CREATE TABLE IF NOT EXISTS objects (
      id TEXT PRIMARY KEY,
      content TEXT,
      created_at DATETIME
    );
  SQL
  puts "Database initialized successfully: #{DB_FILE}"
end
