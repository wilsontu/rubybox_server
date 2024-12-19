require 'sinatra'
require 'securerandom'
require 'sqlite3'
require 'json'

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

# Make endpoints return JSON files instead of plain text
before do
    content_type :json
end

# Upload Object
post '/object' do
    id = params['id'] || SecureRandom.uuid
    content = request.body.read
    created_at = Time.now.strftime('%Y-%m-%d %H:%M:%S')
    DB.execute('INSERT INTO objects (id, content, created_at) VALUES (?, ?, ?)', [id, content, created_at])
    # Response in JSON
    { 
        message: "Object stored successfully!",
        id: id,
        content: content,
        created_at: created_at
    }.to_json
end

# Fetch object
get '/object/:id' do
    id = params['id']
    result = DB.execute("SELECT content FROM objects WHERE id = ?", id).first
    halt 404, { message: 'Object not found' }.to_json unless result
    { 
        id: id,
        content: result['content'],
        created_at: result['created_at']
    }.to_json
end

# Delete object
delete '/object/:id' do
    id = params['id']
    DB.execute("DELETE FROM objects WHERE id = ?", id)
    if DB.changes == 0
        halt 404, { message: "Object not found" }.to_json
    else
        {
            message: "Object deleted successfully",
            id: id
        }.to_json
    end
    
end

# List all objects
get '/objects' do
    rows = DB.execute("SELECT id, content, created_at FROM objects ORDER BY created_at")
    if rows.empty?
        {message: "No objects stored."}.to_json
    else
        rows.map do |row|
            {
                id: row['id'],
                content: row['content'],
                created_at: row['created_at']
            }
        end.to_json
    end
end
