#!/bin/bash

# Monitoring Stack Setup Script
# Run this script on the monitoring server

set -e

echo "🔧 Setting up Prometheus and Grafana monitoring stack..."

# Check if Docker is running
if ! docker info > /dev/null 2>&1; then
    echo "❌ Docker is not running. Please start Docker first."
    exit 1
fi

# Check if docker-compose is available
if ! command -v docker-compose &> /dev/null; then
    echo "❌ docker-compose is not installed."
    exit 1
fi

# Navigate to monitoring directory
cd /opt/monitoring

# Start the monitoring stack
echo "🚀 Starting monitoring services..."
docker-compose up -d

# Wait for services to start
echo "⏳ Waiting for services to start..."
sleep 30

# Check if services are running
if docker-compose ps | grep -q "Up"; then
    echo "✅ Monitoring services are running!"
    echo ""
    echo "🌐 Service URLs:"
    echo "   - Prometheus: http://$(curl -s ifconfig.me):9090"
    echo "   - Grafana: http://$(curl -s ifconfig.me):3000 (admin/admin123)"
    echo "   - Node Exporter: http://$(curl -s ifconfig.me):9100"
    echo ""
    echo "📊 Default Grafana credentials:"
    echo "   Username: admin"
    echo "   Password: admin123"
    echo ""
    echo "🎯 Next steps:"
    echo "1. Access Grafana and import Kubernetes dashboards"
    echo "2. Configure alerting channels"
    echo "3. Set up additional monitoring targets"
else
    echo "❌ Failed to start monitoring services"
    docker-compose logs
    exit 1
fi
