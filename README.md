# RubyBox Server

**RubyBox Server** is a simple HTTP-based object storage server built with Ruby and Sinatra. It allows users to upload, retrieve, list, and delete objects, simulating a lightweight storage API. This project is designed for learning and experimentation, focusing on clean code, REST API design, and test automation.

---

## Table of Contents
- [Features](#features)
- [Requirements](#requirements)
- [Setup and Installation](#setup-and-installation)
- [API Endpoints](#api-endpoints)
- [Usage](#usage)
- [Testing](#testing)
- [Future Enhancements](#future-enhancements)
- [Contributing](#contributing)
- [License](#license)

---

## Features

- **Upload Objects**: Store data in memory with auto-generated or user-specified IDs.
- **Retrieve Objects**: Fetch stored data using a unique ID.
- **List Objects**: List all stored object IDs.
- **Delete Objects**: Remove objects by ID.
- **Simple RESTful API**: Clean and minimal HTTP endpoints.
- **In-Memory Storage**: Fast storage for small-scale testing and learning.
- **Test Automation**: RSpec tests for API functionality.

---

## Requirements

- **Ruby**: Version 3.0 or higher
- **Sinatra**: Lightweight web framework
- **RSpec**: For test automation
- **curl** or any HTTP client (e.g., Postman) for API testing
- Optional: Docker (for containerized deployment)

---

## Setup and Installation

1. **Clone the repository**:
   ```bash
   git clone https://github.com/your-username/rubybox-server.git
   cd rubybox-server
