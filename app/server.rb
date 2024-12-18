require 'sinatra'
require 'securerandom'
require 'sqlite3'

# Open storage.db
DB_FILE = File.expand_path('../storage.db', __dir__)

# If storage.db does not exist, create a new storage.db by calling db_setup.rb
unless File.exist?(DB_FILE)
    puts "Database not found. Initializing..."
    success = system("ruby \"#{File.expand_path('../database/db_setup.rb', __dir__)}\"")
    raise "Failed to initialize the database!" unless success
end

DB = SQLite3::Database.new DB_FILE
DB.results_as_hash = true

# Upload Object
post '/object' do
    id = params['id'] || SecureRandom.uuid
    content = request.body.read
    created_at = Time.now.strftime('%Y-%m-%d %H:%M:%S')
    DB.execute('INSERT INTO objects (id, content, created_at) VALUES (?, ?, ?)', [id, content, created_at])
    "Object stored with ID: #{id}"
end

# Fetch object
get '/object/:id' do
    id = params['id']
    result = DB.execute("SELECT content FROM objects WHERE id = ?", id).first
    halt 404, 'Object not found' unless result
    result['content']
end

# Delete object
delete '/object/:id' do
    id = params['id']
    result = DB.execute("DELETE FROM objects WHERE id = ?", id)
    halt(404, "Object not found") if result == 0
    "Object deleted"
end

# List all objects
get '/objects' do
    rows = DB.execute("SELECT id, content, created_at FROM objects ORDER BY created_at")
    if rows.empty?
        "No objects stored."
    else
        rows.map do |row|
            "ID: #{row['id']}, Content: #{row['content']}, Created_at: #{row['created_at']}"
        end.join("\n")
    end
end
