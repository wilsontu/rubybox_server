require 'rack/test'
require_relative '../app/server'

RSpec.describe 'File Upload Server' do
    include Rack::Test::Methods

    def app
        Sinatra::Application
    end

    # Test Case 1: Basic GET Request
    it 'returns 200 OK for the root route' do
        get '/' # Simulate a GET request to /
        expect(last_response.status).to eq(200) # Assert HTTP status is 200
    end

    # Test Case 2: Test upload to object
    it 'creates a new object' do
        current_time = Time.now
        post '/object', { content: 'Testing 1'} # Simulate a post request to /object
        expect(last_response.status).to eq(200) # Assert HTTP status is 200

        # Validate response body to be correct
        response_body = JSON.parse(last_response.body)
        expect(response_body['message']).to eq("Object stored successfully!")
        expect(response_body['content']).to eq("Testing 1")
        expect(Time.parse(response_body['created_at'])).to be_between(current_time - 5, current_time + 5)
    end

    # Test Case 3: Test GET receives the correct object
    it 'retrieves an object by ID' do
        # Post a new object first
        post '/object', { content: "Testing 2"}
        expect(last_response.status).to eq(200)
        post_response = JSON.parse(last_response.body)
        uuid = post_response['id']

        # Test Get on the uuid of the object posted
        get "/object/#{uuid}"
        expect(last_response.status).to eq(200)
        get_response = JSON.parse(last_response.body)

        # Validate that the content/created_at fields are correct
        expect(post_response['id']).to eq(get_response['id'])
        expect(post_response['content']).to eq(get_response['content'])
        expect(post_response['created_at']).to eq(get_response['created_at'])
    end

    # Test Case 4: Test LIST returns the correct number of objects
    it 'lists all objects' do
        get '/objects'
        expect(last_response.status).to eq(200)
        
        # Validte the number of objects stored
        response_body = last_response.body
        expect(response_body['objects'].size).to eq(2)
        expect(response_body['total_count']).to eq(2)
    end

end
