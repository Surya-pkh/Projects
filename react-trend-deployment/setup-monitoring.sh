#!/bin/bash

# Trend App Monitoring Setup Script
# This script configures comprehensive monitoring for the React application

set -e

echo "🔧 Setting up Trend App Monitoring..."
echo "====================================="

# Apply monitoring configuration
echo "📊 Applying monitoring configuration..."
kubectl apply -f monitoring/trend-app-monitoring.yaml

# Check if monitoring namespace exists, create if not
if ! kubectl get namespace monitoring >/dev/null 2>&1; then
    echo "📦 Creating monitoring namespace..."
    kubectl create namespace monitoring
fi

# Create ServiceMonitor for trend-app
echo "🎯 Creating ServiceMonitor for trend-app..."
cat <<EOF | kubectl apply -f -
apiVersion: monitoring.coreos.com/v1
kind: ServiceMonitor
metadata:
  name: trend-app-monitor
  namespace: monitoring
  labels:
    app: trend-app
spec:
  selector:
    matchLabels:
      app: trend-app
  namespaceSelector:
    matchNames:
      - trend
  endpoints:
  - port: http
    interval: 30s
    path: /metrics
EOF

# Add Prometheus annotations to trend-app deployment
echo "🏷️  Adding Prometheus annotations to trend-app..."
kubectl patch deployment trend-app -n trend -p '{
  "spec": {
    "template": {
      "metadata": {
        "annotations": {
          "prometheus.io/scrape": "true",
          "prometheus.io/port": "80",
          "prometheus.io/path": "/metrics"
        }
      }
    }
  }
}'

# Update Prometheus configuration to include trend-app
echo "⚙️  Updating Prometheus configuration..."
kubectl create configmap prometheus-config -n monitoring --from-file=monitoring/trend-app-monitoring.yaml --dry-run=client -o yaml | kubectl apply -f -

# Restart Prometheus to pick up new configuration
echo "🔄 Restarting Prometheus..."
kubectl rollout restart deployment prometheus -n monitoring

# Wait for Prometheus to be ready
echo "⏳ Waiting for Prometheus to be ready..."
kubectl wait --for=condition=available --timeout=120s deployment/prometheus -n monitoring

# Get monitoring URLs
GRAFANA_URL=$(kubectl get svc grafana -n monitoring -o jsonpath='{.status.loadBalancer.ingress[0].hostname}' 2>/dev/null || echo "pending")
PROMETHEUS_URL=$(kubectl get svc prometheus -n monitoring -o jsonpath='{.spec.clusterIP}' 2>/dev/null || echo "pending")

echo ""
echo "✅ Monitoring Setup Complete!"
echo "=============================="
echo ""
echo "📊 Monitoring URLs:"
echo "🎯 Grafana Dashboard: http://${GRAFANA_URL}:3000"
echo "   📧 Username: admin"
echo "   🔑 Password: admin123"
echo ""
echo "🔍 Prometheus: http://${PROMETHEUS_URL}:9090 (internal)"
echo ""
echo "📈 To access Prometheus externally:"
echo "   kubectl port-forward -n monitoring svc/prometheus 9090:9090"
echo ""
echo "🔗 Application URL: http://a33f4d4d9655c4121a50242bb0a3942b-321113.us-west-2.elb.amazonaws.com"
echo ""
echo "📋 What's Monitored:"
echo "   ✅ Application Health & Uptime"
echo "   ✅ CPU & Memory Usage"
echo "   ✅ HTTP Request Metrics"
echo "   ✅ Pod Restart Counts"
echo "   ✅ Network I/O"
echo "   ✅ Kubernetes Events"
echo ""
echo "🚨 Alerts Configured:"
echo "   ⚠️  High CPU Usage (>80%)"
echo "   ⚠️  High Memory Usage (>80%)"
echo "   🔴 Application Down"
echo "   🔴 Pod Crash Looping"
echo ""
echo "📖 Next Steps:"
echo "   1. Open Grafana dashboard"
echo "   2. Import the trend-app dashboard"
echo "   3. Configure notification channels for alerts"
echo "   4. Set up log aggregation (optional)"

# Show current monitoring status
echo ""
echo "📊 Current Monitoring Status:"
kubectl get pods -n monitoring
echo ""
kubectl get svc -n monitoring
