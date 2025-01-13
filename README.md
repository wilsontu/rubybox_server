# Ruby HTTP Server

## Overview
Ruby HTTP Server is a lightweight, RESTful API server built using Ruby and Sinatra. It supports CRUD operations, file uploads, authentication, and pagination. The application is fully containerized with Docker for consistent deployment and includes comprehensive test coverage with RSpec.

---

## Features
- **RESTful API**: Fully functional CRUD operations for objects and files.
- **Authentication**: Basic Authentication secures sensitive routes.
- **File Uploads**: Upload and manage files with MIME type validation.
- **Database**: SQLite3 integration for lightweight storage.
- **Testing**: RSpec and Rack::Test ensure reliable and robust functionality.
- **Docker**: Containerized application for consistent deployment across environments.

---

## Getting Started

### 1. Clone the Repository
\`\`bash
git clone https://github.com/yourusername/ruby-http-server.git
cd ruby-http-server
\`\`

### 2. Set Up Environment Variables
Create an `.env` file in the project root:
\`\`plaintext
APP_USERNAME=admin
APP_PASSWORD=secret
DATABASE_FILE=storage.db
\`\`

### 3. Run with Docker
Build and run the application using Docker:
\`\`bash
docker build -t ruby_http_server .
docker run -p 4567:4567 ruby_http_server
\`\`

### 4. Run Tests
Set up the test environment and run tests:
\`\`bash
ruby setup_test_environment.rb
rspec
\`\`

---

## API Endpoints

### Public Routes
- **`GET /objects`**: List all objects with pagination.
- **`GET /object/:id`**: Retrieve an object by ID.

### Restricted Routes
- **`POST /object`**: Create a new object (requires authentication).
- **`DELETE /object/:id`**: Delete an object by ID (requires authentication).
- **`POST /upload`**: Upload a file (requires authentication).
- **`DELETE /upload/:id`**: Delete a file by ID (requires authentication).

---

## Development and Testing

### Development
1. Install dependencies:
   \`\`bash
   bundle install
   \`\`
2. Run the server:
   \`\`bash
   ruby app/server.rb
   \`\`

### Testing
1. Set up the test environment:
   \`\`bash
   ruby setup_test_environment.rb
   \`\`
2. Run tests with RSpec:
   \`\`bash
   rspec
   \`\`

---

## Docker

### Build the Docker Image
\`\`bash
docker build -t ruby_http_server .
\`\`

### Run the Docker Container
\`\`bash
docker run -p 4567:4567 ruby_http_server
\`\`

---

## License
This project is open-source and available under the MIT License.
