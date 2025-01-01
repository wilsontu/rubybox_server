require 'dotenv'
require 'rack/test'
require 'rspec'

# Load the test environment variables
Dotenv.load('.env.test')
TEST_USERNAME = ENV['APP_USERNAME']
TEST_PASSWORD = ENV['APP_PASSWORD']
ENV['RACK_ENV'] = 'test'

RSpec.configure do |config|
  # Include Rack::Test methods
  config.include Rack::Test::Methods

  # Define the Sinatra app for Rack::Test
  def app
    Sinatra::Application
  end

  # RSpec expectations configuration
  config.expect_with :rspec do |expectations|
    expectations.include_chain_clauses_in_custom_matcher_descriptions = true
  end

  # RSpec mocks configuration
  config.mock_with :rspec do |mocks|
    mocks.verify_partial_doubles = true
  end

  # Apply shared context metadata to host groups and examples
  config.shared_context_metadata_behavior = :apply_to_host_groups

  # Run specs in random order to surface order dependencies
  config.order = :random

  # Seed global randomization for reproducibility
  Kernel.srand config.seed
end
