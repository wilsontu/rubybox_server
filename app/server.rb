require 'sinatra'
require 'securerandom'
require 'sqlite3'
require 'json'

############### Project Directories and Paths ###############

#/
#  DATABASE 
#/

# Database file path
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

#/
#  UPLOADS 
#/

# Uploads folder path
UPLOADS_DIR = File.expand_path('../uploads', __dir__)

# Ensure uploads folder exists
Dir.mkdir(UPLOADS_DIR) unless Dir.exist? UPLOADS_DIR


################ HTTP REQUESTS AND RESPONSES ###############

#/
#  OBJECTS
#/

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
    result = DB.execute("SELECT * FROM objects WHERE id = ?", id).first
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

#/
#  UPLOADS
#/

# Upload FILE
post '/upload' do
    id = params['id'] || SecureRandom.uuid

    # Get sinatra's file object: {filename: "example.pdf", type: # MIME type of the file, tempfile: # temporary file location}
    file = params['file']
    halt 404, { error: 'No file provided' }.to_json unless file

    # Write the file path to uploads folder with file_name: uuid of the file
    file_path = File.join(UPLOADS_DIR, id)
    File.open(file_path, 'wb') { |f| f.write(file[:tempfile].read)} # Reads the file from temp location and writes it to uploads folder

    uploaded_at = Time.now.strftime('%Y-%m-%d %H:%M:%S')
    # Insert file metadata into the database
    DB.execute('INSERT INTO uploads (id, file_name, file_path, content_type, uploaded_at) VALUES (?, ?, ?, ?, ?)', [id, file[:filename], file_path, file[:type], uploaded_at])
    # Response in JSON
    { 
        message: "File uploaded successfully!",
        id: id,
        file_name: file[:filename],
        uploaded_at: uploaded_at
    }.to_json
end

# Fetch FILE
get '/upload/:id' do
    id = params['id']
    result = DB.execute("SELECT * FROM uploads WHERE id = ?", id).first
    halt 404, { message: 'File not found' }.to_json unless result

    # Send the file
    send_file result['file_path'], file_name: result['file_name'], type: result['content_type']
end

# Delete FILE
delete '/upload/:id' do
    id = params['id']
    file_to_delete = DB.execute("SELECT * FROM uploads WHERE id = ?", id).first
    DB.execute("DELETE FROM uploads WHERE id = ?", id)
    if DB.changes == 0
        halt 404, { message: 'File does not exist' }.to_json
    else
        File.delete(file_to_delete["file_path"]) if File.exist? file_to_delete["file_path"]
        { message: "File deleted successfully" }.to_json
    end
end

# List all files in the FILES table
get '/uploads' do
    rows = DB.execute("SELECT * FROM uploads ORDER BY uploaded_at")
    if rows.empty?
        {message: "No objects stored."}.to_json
    else
        rows.map do |row|
            {
                id: row['id'],
                file_name: row['file_name'],
                created_at: row['uploaded_at']
            }
        end.to_json
    end
end

