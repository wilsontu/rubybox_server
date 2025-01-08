# Use the official Ruby base image
FROM ruby:3.2-slim

# Set environment variables
ENV APP_HOME /usr/src/app
WORKDIR $APP_HOME

# Install dependencies
RUN apt-get update -qq && apt-get install -y \
  build-essential \
  libsqlite3-dev \
  && rm -rf /var/lib/apt/lists/*

# Copy the Gemfile and Gemfile.lock
COPY Gemfile Gemfile.lock ./

# Install the required gems
RUN bundle install --without development test

# Copy the application code
COPY . .

# Expose the port the app runs on
EXPOSE 4567

# Set environment variables for production (override with .env in docker-compose or at runtime)
ENV RACK_ENV=production
ENV DATABASE_FILE storage.db

# Run db_setup first to setup a database
RUN ruby database/db_setup.rb

# Run the server
CMD ["ruby", "app/server.rb"]
