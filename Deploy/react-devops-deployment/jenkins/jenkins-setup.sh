#!/bin/bash

# Jenkins Setup Script
# Run this script on the Jenkins server after Terraform deployment

set -e

JENKINS_URL="http://localhost:8080"
JENKINS_USER="admin"

echo "🔧 Setting up Jenkins..."

# Wait for Jenkins to start
echo "⏳ Waiting for Jenkins to start..."
while ! curl -s $JENKINS_URL > /dev/null; do
    sleep 10
    echo "Still waiting..."
done

echo "✅ Jenkins is running!"

# Get initial admin password
INITIAL_PASSWORD=$(sudo cat /var/lib/jenkins/secrets/initialAdminPassword)
echo "🔑 Initial admin password: $INITIAL_PASSWORD"

echo "📝 Manual steps required:"
echo "1. Open Jenkins at $JENKINS_URL"
echo "2. Use password: $INITIAL_PASSWORD"
echo "3. Install suggested plugins"
echo "4. Create admin user"
echo "5. Install additional plugins from plugins.txt"
echo "6. Configure Docker Hub credentials"
echo "7. Configure AWS credentials"
echo "8. Configure GitHub webhook"

# Install Jenkins CLI
wget -O jenkins-cli.jar $JENKINS_URL/jnlpJars/jenkins-cli.jar

echo "🎯 Jenkins setup script completed!"
echo "🌐 Access Jenkins at: $JENKINS_URL"
