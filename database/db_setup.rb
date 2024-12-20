require 'sqlite3'

DB_FILE = File.expand_path('../storage.db', __dir__)

if File.exist?(DB_FILE)
  puts "Database already exists: #{DB_FILE}. Skipping setup."
else
  # Create a table for objects storage
  db = SQLite3::Database.new(DB_FILE)
  db.execute <<-SQL
    CREATE TABLE IF NOT EXISTS objects (
      id TEXT PRIMARY KEY,
      content TEXT,
      created_at DATETIME
    );
  SQL
  puts "Object table initialized successfully: #{DB_FILE}"

  # Create a table for file storage
  db.execute <<~SQL
      CREATE TABLE IF NOT EXISTS uploads (
        id TEXT PRIMARY KEY,
        file_name TEXT,
        file_path TEXT,
        content_type TEXT,
        uploaded_at DATETIME
      )
  SQL
  puts "Files table initialized successfully"
  puts "Database initialized successfully"
end
