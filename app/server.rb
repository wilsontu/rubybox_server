require 'sinatra'
require 'securerandom'
require 'sqlite3'
require 'json'

######################### Constants #########################

DEFAULT_RESULTS_PER_PAGE = 10
DEFAULT_NUM_PAGES = 1
MAX_RESULTS_PER_PAGE = 50

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

# Restrict file types that could be uploaded
ALLOWED_MIME_TYPES = [
    'text/plain',           # .txt
    'application/pdf',      # pdf
    'image/jpeg',           # jpeg
    'image/png',            # png
    'image/gif'             # gif
]


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
    # Set default values for pagination
    page = params['page']&.to_i || DEFAULT_NUM_PAGES
    per_page = params['per_page']&.to_i || DEFAULT_RESULTS_PER_PAGE

    # Handle error if per_page <= 0 or if per_page > max_results_per_page
    halt 400, { message: "Invalid pagination parameter, per_page must be > 0" }.to_json unless per_page > 0
    halt 400, { message: "Invalid pagination parameter, results per page must be <= #{MAX_RESULTS_PER_PAGE}" }.to_json unless per_page <= MAX_RESULTS_PER_PAGE


    # Calculate the offset
    offset = (page - 1) * per_page

    # Fetch the total count of objects for metadata
    rows = DB.execute("SELECT id, content, created_at FROM objects ORDER BY created_at LIMIT ? OFFSET ?", [per_page, offset])

    # Get the total count of objects for metadata
    total_count = DB.execute("SELECT COUNT(*) FROM objects")[0].values[0]

    # Get total number of pages
    num_pages = (total_count.to_f / per_page).ceil

    # Error handling if page is out of range
    halt 400, { message: "Page #{page} out of range. There are only #{num_pages} pages total" }.to_json unless page <= num_pages

    # Format the response
    if rows.empty?
        {message: "No objects stored."}.to_json
    else
        {
            objects: rows.map { |row| { id: row['id'], content: row['content'], created_at: row['created_at']}},
            page: page,
            per_page: per_page,
            total_count: total_count,
            num_pages: (total_count.to_f/per_page).ceil
        }.to_json
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
    halt 400, { error: 'No file provided' }.to_json unless file

    # # Validate file type
    content_type = file[:type]
    unless ALLOWED_MIME_TYPES.include?(content_type)
        halt 400, { error: "Unsupported file type: #{content_type}" }.to_json
    end

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
    # Set default values for pagination
    page = params['page']&.to_i || DEFAULT_NUM_PAGES
    per_page = params['per_page']&.to_i || DEFAULT_RESULTS_PER_PAGE

    # Handle error if per_page <= 0 or if per_page > max_results_per_page
    halt 400, { message: "Invalid pagination parameter, per_page must be > 0" }.to_json unless per_page > 0
    halt 400, { message: "Invalid pagination parameter, results per page must be <= #{MAX_RESULTS_PER_PAGE}" }.to_json unless per_page <= MAX_RESULTS_PER_PAGE

    # Calculate the offset
    offset = (page - 1) * per_page

    # Fetch the total count of objects for metadata
    rows = DB.execute("SELECT id, file_name, uploaded_at FROM uploads ORDER BY uploaded_at LIMIT ? OFFSET ?", [per_page, offset])

    # Get the total count of objects for metadata
    total_count = DB.execute("SELECT COUNT(*) FROM uploads")[0].values[0]

    # Get total number of pages
    num_pages = (total_count.to_f / per_page).ceil

    # Error handling if page is out of range
    halt 400, { message: "Page #{page} out of range. There are only #{num_pages} pages total" }.to_json unless page <= num_pages

    # Format the response
    if rows.empty?
        {message: "No files stored."}.to_json
    else
        {
            objects: rows.map { |row| { id: row['id'], file_name: row['file_name'], uploaded_at: row['uploaded_at']}},
            page: page,
            per_page: per_page,
            total_count: total_count,
            num_pages: (total_count.to_f/per_page).ceil
        }.to_json
    end
end

