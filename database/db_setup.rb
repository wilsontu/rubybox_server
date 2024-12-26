require 'sqlite3'

def setup_database(db_file)

  if File.exist?(db_file)
    puts "Database already exists: #{db_file}. Skipping setup."
  else
    # Create a table for objects storage
    db = SQLite3::Database.new(db_file)
    db.execute <<-SQL
      CREATE TABLE IF NOT EXISTS objects (
        id TEXT PRIMARY KEY,
        content TEXT,
        created_at DATETIME
      );
    SQL
    puts "Object table initialized successfully: #{db_file}"

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
end

# Only run setup if called directly
if __FILE__ == $0
    file_name = ARGV[0] || "storage.db" # Default to 'storage.db' if no argument
    db_file = File.expand_path("../#{file_name}", __dir__)
    setup_database(db_file)
end