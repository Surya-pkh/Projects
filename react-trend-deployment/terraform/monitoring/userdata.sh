#!/bin/bash

# Update system
yum update -y
yum install -y docker git

# Start Docker
systemctl start docker
systemctl enable docker

# Create directories for persistent storage
mkdir -p /prometheus-data /grafana-data

# Set retention period for Prometheus
cat << EOF > /prometheus-data/prometheus.yml
global:
  scrape_interval: 15s
  evaluation_interval: 15s
  scrape_timeout: 10s
  external_labels:
    monitor: 'trend-app-monitor'

scrape_configs:
  - job_name: prometheus
    static_configs:
      - targets: ['localhost:9090']

  - job_name: node
    static_configs:
      - targets: ['localhost:9100']
EOF

# Start node exporter
docker run -d \
  --name node-exporter \
  --net="host" \
  --pid="host" \
  -v "/:/host:ro,rslave" \
  quay.io/prometheus/node-exporter:latest \
  --path.rootfs=/host

# Start Prometheus
docker run -d \
  --name prometheus \
  -p 9090:9090 \
  -v /prometheus-data:/prometheus \
  -v /prometheus-data/prometheus.yml:/etc/prometheus/prometheus.yml \
  prom/prometheus \
  --config.file=/etc/prometheus/prometheus.yml \
  --storage.tsdb.retention.time=${prometheus_retention} \
  --web.enable-lifecycle

# Start Grafana
docker run -d \
  --name grafana \
  -p 3000:3000 \
  -v /grafana-data:/var/lib/grafana \
  -e "GF_SECURITY_ADMIN_PASSWORD=${grafana_password}" \
  grafana/grafana

# Wait for Grafana to start
sleep 10

# Configure Grafana datasource and dashboards
curl -X POST \
  -H "Content-Type: application/json" \
  -d '{
    "name":"Prometheus",
    "type":"prometheus",
    "url":"http://localhost:9090",
    "access":"proxy",
    "isDefault":true
  }' \
  http://admin:${grafana_password}@localhost:3000/api/datasources
