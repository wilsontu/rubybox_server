require 'sqlite3'
require 'dotenv'
require_relative '../database/db_setup'

# Load test environment variables
Dotenv.load('.env.test')

# Path to the test database file
TEST_DB_FILE = File.expand_path("../#{ENV['DATABASE_FILE'] || 'test.db'}", __dir__)

# Ensure the test database is initialized
def prepare_test_database
  # Clean up existing test database
  if File.exist?(TEST_DB_FILE)
    puts "Cleaning up existing test database: #{TEST_DB_FILE}"
    File.delete(TEST_DB_FILE)
  end

  # Initialize a new test database
  setup_database(TEST_DB_FILE)
  puts "Test database initialized: #{TEST_DB_FILE}"
end

# Main script
if __FILE__ == $0
  prepare_test_database
end
