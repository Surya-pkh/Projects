#!/bin/bash

# Test script for Docker image
echo "Testing Docker image locally..."

# Build the image
echo "Building Docker image..."
docker build -t trend-app:test .

# Run container
echo "Starting container on port 3001..."
docker run -d --name trend-test -p 3001:3000 trend-app:test

# Wait for container to start
echo "Waiting for container to start..."
sleep 10

# Test the application
echo "Testing application..."
if curl -f http://localhost:3001/health 2>/dev/null; then
    echo "✅ Health check passed!"
elif curl -f http://localhost:3001/ 2>/dev/null; then
    echo "✅ Application is responding!"
else
    echo "❌ Application test failed"
    echo "Container logs:"
    docker logs trend-test
    docker rm -f trend-test
    exit 1
fi

# Check if it's serving on port 3000 internally
echo "Container info:"
docker ps | grep trend-test

# Cleanup
echo "Cleaning up test container..."
docker rm -f trend-test

echo "✅ Docker image test completed successfully!"
