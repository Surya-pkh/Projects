#!/bin/bash

# Wait for Grafana to be ready
until $(curl --output /dev/null --silent --head --fail http://localhost:3000); do
    printf '.'
    sleep 5
done

# Add Prometheus data source
curl -X POST \
  -H "Content-Type: application/json" \
  -d '{
    "name":"Prometheus",
    "type":"prometheus",
    "url":"http://prometheus:9090",
    "access":"proxy",
    "isDefault":true
  }' \
  http://admin:${GRAFANA_PASSWORD}@localhost:3000/api/datasources

# Add Kubernetes dashboard
curl -X POST \
  -H "Content-Type: application/json" \
  -d '{
    "dashboard": {
      "id": null,
      "title": "Kubernetes Cluster Monitoring",
      "tags": ["kubernetes"],
      "timezone": "browser",
      "panels": [
        {
          "title": "CPU Usage",
          "type": "graph",
          "datasource": "Prometheus",
          "targets": [
            {
              "expr": "sum(rate(container_cpu_usage_seconds_total{container!=\"\"}[5m])) by (pod)",
              "legendFormat": "{{pod}}"
            }
          ]
        },
        {
          "title": "Memory Usage",
          "type": "graph",
          "datasource": "Prometheus",
          "targets": [
            {
              "expr": "sum(container_memory_usage_bytes{container!=\"\"}) by (pod)",
              "legendFormat": "{{pod}}"
            }
          ]
        }
      ]
    },
    "overwrite": false
  }' \
  http://admin:${GRAFANA_PASSWORD}@localhost:3000/api/dashboards/db

# Add Application dashboard
curl -X POST \
  -H "Content-Type: application/json" \
  -d '{
    "dashboard": {
      "id": null,
      "title": "React Application Monitoring",
      "tags": ["react"],
      "timezone": "browser",
      "panels": [
        {
          "title": "HTTP Request Rate",
          "type": "graph",
          "datasource": "Prometheus",
          "targets": [
            {
              "expr": "rate(http_requests_total[5m])",
              "legendFormat": "{{handler}}"
            }
          ]
        },
        {
          "title": "Response Time",
          "type": "graph",
          "datasource": "Prometheus",
          "targets": [
            {
              "expr": "rate(http_request_duration_seconds_sum[5m]) / rate(http_request_duration_seconds_count[5m])",
              "legendFormat": "{{handler}}"
            }
          ]
        }
      ]
    },
    "overwrite": false
  }' \
  http://admin:${GRAFANA_PASSWORD}@localhost:3000/api/dashboards/db
