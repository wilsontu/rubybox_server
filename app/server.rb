require 'sinatra'
require 'securerandom'

# In-memory store for objects

STORAGE = {}

# Upload Object
post '/object' do
    id = params['id'] || SecureRandom.uuid
    STORAGE[id] = request.body.read
    "Object stored with ID: #{id}"
end

# Fetch object
get '/object/:id' do
    content = STORAGE[params['id']]
    halt 404, 'Object not found' unless content
    content
end

# Delete object
delete '/object/:id' do
    STORAGE.delete(params['id']) || halt(404, "Object not found")
    "Object deleted"
end

# List all objects
get '/objects' do
    if STORAGE.empty?
        "No objects stored." 
    else
        STORAGE.keys.join("\n")
    end
end