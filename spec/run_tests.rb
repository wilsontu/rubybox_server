# Run the setup_test_environment script
setup_script = File.expand_path('setup_test_environment.rb', __dir__)
puts "Running setup_test_environment..."
puts setup_script
system("ruby #{setup_script}")

if $?.success?
  # Run RSpec tests if setup was successful
  puts "Setup completed successfully. Running RSpec tests..."
  system("rspec")

  # Cleanup: Delete the test database after tests finish
  test_db_file = File.expand_path('test.db', __dir__)
  if File.exist?(test_db_file)
    puts "Cleaning up test database: #{test_db_file}"
    begin
      File.delete(test_db_file)
      puts "Test database deleted successfully."
    rescue Errno::EACCES => e
      puts "Failed to delete test database: #{e.message}"
    end
  else
    puts "Test database not found for cleanup."
  end
else
  # Handle setup failure
  puts "Setup failed. Aborting tests."
  exit(1)
end
