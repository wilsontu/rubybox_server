require 'rack/test'
require 'rspec'
require 'dotenv'
require 'base64'
require_relative '../app/server'

Dotenv.load('.env.test')

RSpec.describe 'Public Routes' do
    include Rack::Test::Methods
  
    def app
      Sinatra::Application
    end

    def current_time
        Time.now.strftime('%Y-%m-%d %H:%M:%S')
    end
  
    it 'allows access to GET /objects' do
      get '/objects'
      expect(last_response.status).to eq(200)
    end
end

RSpec.describe 'Restricted Routes' do
  include Rack::Test::Methods

  def app
    Sinatra::Application
  end

  def current_time
    Time.now.strftime('%Y-%m-%d %H:%M:%S')
  end

  context 'when no authorization is provided' do
    it 'denies access to POST /object' do
      post '/object', 'Test content', { 'CONTENT_TYPE' => 'text/plain' }
      expect(last_response.status).to eq(401)
      expect(JSON.parse(last_response.body)['message']).to eq('Unauthorized')
    end

    it 'denies access to DELETE /object/:id' do
      # Ensure there's at least one object to attempt deleting
      authorize TEST_USERNAME, TEST_PASSWORD
      post '/object', 'Test content', { 'CONTENT_TYPE' => 'text/plain' }
      expect(last_response.status).to eq(200)
      id = JSON.parse(last_response.body)['id']

      # Remove authorization
      header 'Authorization', nil
      delete "/object/#{id}"
      expect(last_response.status).to eq(401)
      expect(JSON.parse(last_response.body)['message']).to eq('Unauthorized')
    end
  end

  context 'when authorization is provided' do
    it 'allows access to POST /object' do
      authorize TEST_USERNAME, TEST_PASSWORD
      post '/object', 'Test content', { 'CONTENT_TYPE' => 'text/plain' }
      expect(last_response.status).to eq(200)
      response_data = JSON.parse(last_response.body)
      expect(response_data['message']).to eq('Object created successfully!')
      expect(response_data['content']).to eq('Test content')
    end

    it 'allows access to DELETE /object/:id' do
      authorize TEST_USERNAME, TEST_PASSWORD
      post '/object', 'Test content', { 'CONTENT_TYPE' => 'text/plain' }
      expect(last_response.status).to eq(200)
      id = JSON.parse(last_response.body)['id']

      delete "/object/#{id}"
      expect(last_response.status).to eq(200)
      expect(JSON.parse(last_response.body)['message']).to eq('Object deleted successfully')
    end
  end
end


