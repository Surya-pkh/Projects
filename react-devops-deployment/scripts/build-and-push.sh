#!/bin/bash

# Build and Push Docker Image Script

set -e

# Configuration
DOCKERHUB_USERNAME=${1:-"your-dockerhub-username"}
IMAGE_NAME="react-trend-app"
VERSION=${2:-"latest"}

echo "🔨 Building and pushing Docker image..."
echo "📦 Username: $DOCKERHUB_USERNAME"
echo "🏷️  Image: $IMAGE_NAME:$VERSION"

# Check if Docker is running
if ! docker info > /dev/null 2>&1; then
    echo "❌ Docker is not running. Please start Docker first."
    exit 1
fi

# Navigate to app directory
cd app

# Build the application
echo "📦 Building React application..."
if [ ! -f "package.json" ]; then
    echo "❌ package.json not found. Make sure you're in the correct directory."
    exit 1
fi

npm ci
npm run build

# Build Docker image
echo "🐳 Building Docker image..."
docker build -t $DOCKERHUB_USERNAME/$IMAGE_NAME:$VERSION .
docker tag $DOCKERHUB_USERNAME/$IMAGE_NAME:$VERSION $DOCKERHUB_USERNAME/$IMAGE_NAME:latest

# Login to DockerHub (you'll need to enter credentials)
echo "🔐 Logging in to DockerHub..."
echo "Please enter your DockerHub credentials:"
docker login

# Push the image
echo "📤 Pushing image to DockerHub..."
docker push $DOCKERHUB_USERNAME/$IMAGE_NAME:$VERSION
docker push $DOCKERHUB_USERNAME/$IMAGE_NAME:latest

echo "✅ Image pushed successfully!"
echo "🌐 Image URL: docker.io/$DOCKERHUB_USERNAME/$IMAGE_NAME:$VERSION"
