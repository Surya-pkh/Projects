#!/bin/bash

# Grafana Dashboard Import Script
# Automatically imports dashboards and configures data sources

set -e

GRAFANA_URL="http://aa29945fe1c614be5ae0b521f91e2e87-1553642504.us-west-2.elb.amazonaws.com:3000"
GRAFANA_USER="admin"
GRAFANA_PASS="admin123"

echo "🎨 Setting up Grafana Dashboards..."
echo "=================================="

# Wait for Grafana to be ready
echo "⏳ Waiting for Grafana to be ready..."
until curl -s "$GRAFANA_URL/api/health" >/dev/null 2>&1; do
  echo "Waiting for Grafana..."
  sleep 5
done
echo "✅ Grafana is ready!"

# Add Prometheus data source
echo "📊 Adding Prometheus data source..."
curl -X POST \
  "$GRAFANA_URL/api/datasources" \
  -H "Content-Type: application/json" \
  -u "$GRAFANA_USER:$GRAFANA_PASS" \
  -d '{
    "name": "Prometheus",
    "type": "prometheus",
    "url": "http://prometheus.monitoring.svc.cluster.local:9090",
    "access": "proxy",
    "isDefault": true
  }' || echo "Data source may already exist"

# Import Kubernetes cluster dashboard
echo "📈 Importing Kubernetes Cluster dashboard..."
curl -X POST \
  "$GRAFANA_URL/api/dashboards/import" \
  -H "Content-Type: application/json" \
  -u "$GRAFANA_USER:$GRAFANA_PASS" \
  -d '{
    "dashboard": {
      "id": null,
      "title": "Kubernetes Cluster Monitoring",
      "tags": ["kubernetes"],
      "timezone": "browser",
      "panels": [
        {
          "id": 1,
          "title": "Cluster CPU Usage",
          "type": "graph",
          "targets": [
            {
              "expr": "100 - (avg by(instance) (rate(node_cpu_seconds_total{mode=\"idle\"}[5m])) * 100)",
              "legendFormat": "{{instance}}"
            }
          ],
          "gridPos": {"h": 8, "w": 12, "x": 0, "y": 0}
        },
        {
          "id": 2,
          "title": "Cluster Memory Usage",
          "type": "graph", 
          "targets": [
            {
              "expr": "(1 - (node_memory_MemAvailable_bytes / node_memory_MemTotal_bytes)) * 100",
              "legendFormat": "{{instance}}"
            }
          ],
          "gridPos": {"h": 8, "w": 12, "x": 12, "y": 0}
        },
        {
          "id": 3,
          "title": "Pod Status",
          "type": "stat",
          "targets": [
            {
              "expr": "count by(phase) (kube_pod_status_phase)",
              "legendFormat": "{{phase}}"
            }
          ],
          "gridPos": {"h": 8, "w": 24, "x": 0, "y": 8}
        }
      ],
      "time": {"from": "now-1h", "to": "now"},
      "refresh": "30s"
    },
    "inputs": [
      {
        "name": "DS_PROMETHEUS",
        "type": "datasource",
        "pluginId": "prometheus",
        "value": "Prometheus"
      }
    ],
    "overwrite": true
  }'

# Import Trend App specific dashboard
echo "🎯 Importing Trend App dashboard..."
if [ -f "monitoring/trend-app-dashboard.json" ]; then
  DASHBOARD_JSON=$(cat monitoring/trend-app-dashboard.json)
  curl -X POST \
    "$GRAFANA_URL/api/dashboards/db" \
    -H "Content-Type: application/json" \
    -u "$GRAFANA_USER:$GRAFANA_PASS" \
    -d "$DASHBOARD_JSON" || echo "Dashboard import may have failed"
fi

# Set up alerts
echo "🚨 Setting up basic alerts..."
curl -X POST \
  "$GRAFANA_URL/api/alert-rules" \
  -H "Content-Type: application/json" \
  -u "$GRAFANA_USER:$GRAFANA_PASS" \
  -d '{
    "title": "Trend App Down",
    "condition": "A",
    "data": [
      {
        "refId": "A",
        "queryType": "",
        "relativeTimeRange": {
          "from": 300,
          "to": 0
        },
        "model": {
          "expr": "up{job=\"kubernetes-pods\", pod=~\"trend-app.*\"} == 0",
          "intervalMs": 1000,
          "maxDataPoints": 43200
        }
      }
    ],
    "intervalSeconds": 60,
    "noDataState": "NoData",
    "execErrState": "Alerting",
    "for": "1m"
  }' || echo "Alert setup may have failed (requires newer Grafana version)"

echo ""
echo "✅ Grafana Setup Complete!"
echo "========================="
echo ""
echo "🎨 Grafana Dashboard: $GRAFANA_URL"
echo "👤 Username: $GRAFANA_USER"
echo "🔑 Password: $GRAFANA_PASS"
echo ""
echo "📊 Available Dashboards:"
echo "   • Kubernetes Cluster Monitoring"
echo "   • Trend App Dashboard"
echo ""
echo "🔍 To explore data:"
echo "   1. Go to Explore"
echo "   2. Select Prometheus data source"
echo "   3. Try queries like: up{job=\"kubernetes-pods\"}"
echo ""
echo "📈 Recommended Next Steps:"
echo "   1. Customize dashboard panels"
echo "   2. Set up notification channels"
echo "   3. Configure alert rules"
echo "   4. Add business metric tracking"

# Show current Grafana status
echo ""
echo "📊 Current Grafana Status:"
curl -s "$GRAFANA_URL/api/health" | head -1
