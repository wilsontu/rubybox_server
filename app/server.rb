require 'sinatra'
require 'securerandom'
require 'sqlite3'
require 'json'
require 'rack'
require 'dotenv'
require 'puma'

######################### Constants #########################

DEFAULT_RESULTS_PER_PAGE = 10
DEFAULT_NUM_PAGES = 1
MAX_RESULTS_PER_PAGE = 50

############### Environment and Database Setup ###############

# Load the appropriate .env file based on RACK_ENV
Dotenv.load(
  case ENV['RACK_ENV']
  when 'test'
    '.env.test'
  else
    '.env'
  end
)

puts "server.rb loaded with RACK_ENV=#{ENV['RACK_ENV']}"

# Determine the database file dynamically
DB_FILE = File.expand_path("../#{ENV['DATABASE_FILE'] || 'storage.db'}", __dir__)
puts "Using database file: #{DB_FILE}"

# Handle missing database file in non-test environments
if ENV['RACK_ENV'] != 'test' && !File.exist?(DB_FILE)
  puts "Database file does not exist. Please initialize the database using db_setup."
  exit
end

# Open the database connection
DB = SQLite3::Database.new(DB_FILE)
DB.results_as_hash = true

#################### Middleware and Settings #################

# Ensure all responses are in JSON format
before do
  content_type :json
end

# Authentication for restricted routes
before do
  if (request.path.start_with?('/object') || request.path.start_with?('/upload')) && !request.get?
    auth!
  end
end

def auth!
  auth = Rack::Auth::Basic::Request.new(request.env)
  unless auth.provided? && auth.basic? && auth.credentials && valid_credentials?(auth.credentials)
    response['WWW-Authenticate'] = %(Basic realm="Restricted Area")
    halt 401, { message: 'Unauthorized' }.to_json
  end
end

def valid_credentials?(credentials)
  username, password = credentials
  username == ENV['APP_USERNAME'] && password == ENV['APP_PASSWORD']
end

before do
  puts "Authorization Header: #{request.env['HTTP_AUTHORIZATION']}" if request.env['HTTP_AUTHORIZATION']
end

################ Uploads Directory Setup #####################

UPLOADS_DIR = File.expand_path('../uploads', __dir__)
Dir.mkdir(UPLOADS_DIR) unless Dir.exist?(UPLOADS_DIR)

ALLOWED_MIME_TYPES = [
  'text/plain',           # .txt
  'application/pdf',      # pdf
  'image/jpeg',           # jpeg
  'image/png',            # png
  'image/gif'             # gif
]

################ HTTP REQUESTS AND RESPONSES #################

######################### PUBLIC ROUTES ######################

# Fetch object by ID
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

# List all objects
get '/objects' do
  page = params['page']&.to_i || DEFAULT_NUM_PAGES
  per_page = params['per_page']&.to_i || DEFAULT_RESULTS_PER_PAGE

  halt 400, { message: "Invalid per_page parameter. Must be > 0 and <= #{MAX_RESULTS_PER_PAGE}" }.to_json unless per_page.positive? && per_page <= MAX_RESULTS_PER_PAGE

  keyword = params['keyword']
  start_date = params['start_date']
  end_date = params['end_date']

  where_clauses = []
  parameters = []

  if keyword
    where_clauses << "content LIKE ?"
    parameters << "%#{keyword}%"
  end

  if start_date
    where_clauses << "created_at >= ?"
    parameters << start_date
  end

  if end_date
    where_clauses << "created_at <= ?"
    parameters << end_date
  end

  where_query = where_clauses.any? ? "WHERE #{where_clauses.join(' AND ')}" : ""
  offset = (page - 1) * per_page

  rows = DB.execute("SELECT id, content, created_at FROM objects #{where_query} ORDER BY created_at LIMIT ? OFFSET ?", parameters + [per_page, offset])
  total_count = DB.execute("SELECT COUNT(*) FROM objects #{where_query}", parameters).first.values.first

  if rows.empty?
    { message: "No objects found." }.to_json
  else
    {
      objects: rows.map { |row| { id: row['id'], content: row['content'], created_at: row['created_at'] } },
      page: page,
      per_page: per_page,
      total_count: total_count,
      num_pages: (total_count.to_f / per_page).ceil
    }.to_json
  end
end

######################### RESTRICTED ROUTES ##################

# Upload object
post '/object' do
  id = params['id'] || SecureRandom.uuid
  content = request.body.read
  created_at = Time.now.strftime('%Y-%m-%d %H:%M:%S')
  DB.execute('INSERT INTO objects (id, content, created_at) VALUES (?, ?, ?)', [id, content, created_at])
  {
    message: "Object created successfully!",
    id: id,
    content: content,
    created_at: created_at
  }.to_json
end

# Delete object
delete '/object/:id' do
  id = params['id']
  DB.execute("DELETE FROM objects WHERE id = ?", id)
  if DB.changes.zero?
    halt 404, { message: "Object not found" }.to_json
  else
    { message: "Object deleted successfully", id: id }.to_json
  end
end

# Upload file
post '/upload' do
  id = params['id'] || SecureRandom.uuid
  file = params['file']
  halt 400, { error: 'No file provided' }.to_json unless file

  content_type = file[:type]
  unless ALLOWED_MIME_TYPES.include?(content_type)
    halt 400, { error: "Unsupported file type: #{content_type}" }.to_json
  end

  file_path = File.join(UPLOADS_DIR, id)
  File.open(file_path, 'wb') { |f| f.write(file[:tempfile].read) }

  uploaded_at = Time.now.strftime('%Y-%m-%d %H:%M:%S')
  DB.execute('INSERT INTO uploads (id, file_name, file_path, content_type, uploaded_at) VALUES (?, ?, ?, ?, ?)', [id, file[:filename], file_path, file[:type], uploaded_at])
  {
    message: "File uploaded successfully!",
    id: id,
    file_name: file[:filename],
    uploaded_at: uploaded_at
  }.to_json
end

# Delete file
delete '/upload/:id' do
  id = params['id']
  file_to_delete = DB.execute("SELECT * FROM uploads WHERE id = ?", id).first
  DB.execute("DELETE FROM uploads WHERE id = ?", id)
  if DB.changes.zero?
    halt 404, { message: 'File does not exist' }.to_json
  else
    File.delete(file_to_delete["file_path"]) if File.exist? file_to_delete["file_path"]
    { message: "File deleted successfully" }.to_json
  end
end
