# 📊 Trend App Monitoring Setup Guide

## 🎯 Overview
This guide sets up comprehensive monitoring for your React Trend application using Prometheus and Grafana.

## 🔗 Monitoring URLs

### 🎨 Grafana Dashboard
- **URL**: http://aa29945fe1c614be5ae0b521f91e2e87-1553642504.us-west-2.elb.amazonaws.com:3000
- **Username**: `admin`
- **Password**: `admin123`

### 🔍 Prometheus (Internal)
- **Internal URL**: `http://prometheus.monitoring.svc.cluster.local:9090`
- **Access via Port Forward**: `kubectl port-forward -n monitoring svc/prometheus 9090:9090`

## 🚀 Quick Setup Steps

### 1. Access Grafana
1. Open: http://aa29945fe1c614be5ae0b521f91e2e87-1553642504.us-west-2.elb.amazonaws.com:3000
2. Login with `admin` / `admin123`

### 2. Add Prometheus Data Source
1. Click "Add data source"
2. Select "Prometheus"
3. URL: `http://prometheus.monitoring.svc.cluster.local:9090`
4. Click "Save & Test"

### 3. Import Kubernetes Dashboard
1. Click "+" → "Import"
2. Use ID: `15757` (Kubernetes / System / CoreDNS)
3. Or ID: `8588` (1 Node Exporter for Prometheus Dashboard)
4. Or ID: `3662` (Prometheus 2.0 Overview)

### 4. Create Custom Trend App Dashboard
Use the dashboard JSON from `monitoring/trend-app-dashboard.json`

## 📈 What's Being Monitored

### ✅ Application Metrics
- **Pod Health**: Running/Failed pods
- **HTTP Requests**: Rate and response codes
- **Response Times**: Request latency
- **Error Rates**: 4xx/5xx responses

### ✅ Infrastructure Metrics
- **CPU Usage**: Per pod and cluster-wide
- **Memory Usage**: Current and limits
- **Network I/O**: Incoming/Outgoing traffic
- **Disk Usage**: Storage consumption

### ✅ Kubernetes Metrics
- **Pod Restarts**: Crash loop detection
- **Deployment Status**: Rollout health
- **Service Health**: Endpoint availability
- **Node Status**: Cluster node health

## 🚨 Alerting Rules

### Critical Alerts
- **Application Down**: Triggers when app is unreachable for >1 minute
- **Pod Crash Looping**: Triggers when pods restart frequently
- **High Error Rate**: Triggers when 5xx errors >5% for 5 minutes

### Warning Alerts
- **High CPU Usage**: Triggers when CPU >80% for 2 minutes
- **High Memory Usage**: Triggers when memory >80% for 2 minutes
- **Slow Response Time**: Triggers when latency >2s for 5 minutes

## 📊 Key Dashboards to Create

### 1. Application Overview
```json
{
  "title": "Trend App Overview",
  "panels": [
    "Application Health Status",
    "Request Rate",
    "Error Rate",
    "Response Time",
    "Active Users"
  ]
}
```

### 2. Infrastructure Health
```json
{
  "title": "Infrastructure Health",
  "panels": [
    "Pod Status",
    "CPU Usage",
    "Memory Usage", 
    "Network I/O",
    "Disk Usage"
  ]
}
```

### 3. Business Metrics
```json
{
  "title": "Business Metrics", 
  "panels": [
    "Page Views",
    "User Sessions",
    "Cart Additions",
    "Checkout Rate",
    "Revenue Tracking"
  ]
}
```

## 🔧 Useful Prometheus Queries

### Application Health
```promql
# Pod availability
up{job="kubernetes-pods", pod=~"trend-app.*"}

# Pod count
count(kube_pod_info{pod=~"trend-app.*", phase="Running"})

# Memory usage
container_memory_usage_bytes{pod=~"trend-app.*"} / 1024 / 1024

# CPU usage 
rate(container_cpu_usage_seconds_total{pod=~"trend-app.*"}[5m]) * 100
```

### HTTP Metrics
```promql
# Request rate
rate(nginx_http_requests_total{pod=~"trend-app.*"}[5m])

# Error rate
rate(nginx_http_requests_total{pod=~"trend-app.*", status=~"5.."}[5m]) / 
rate(nginx_http_requests_total{pod=~"trend-app.*"}[5m]) * 100

# Response time
histogram_quantile(0.95, nginx_http_request_duration_seconds_bucket{pod=~"trend-app.*"})
```

## 🎯 Advanced Setup

### Enable Application Metrics
Add to your nginx.conf:
```nginx
location /metrics {
    stub_status on;
    access_log off;
    allow all;
}
```

### Custom Application Metrics
Add to your React app:
```javascript
// Track page views
window.gtag('event', 'page_view', {
  page_title: document.title,
  page_location: window.location.href
});

// Track user interactions
window.gtag('event', 'button_click', {
  event_category: 'engagement',
  event_label: 'add_to_cart'
});
```

## 🔔 Setting Up Alerts

### 1. Email Notifications
In Grafana:
1. Go to Alerting → Notification channels
2. Add Email notification
3. Configure SMTP settings

### 2. Slack Integration
1. Create Slack webhook
2. Add as notification channel
3. Test alert delivery

### 3. PagerDuty (Production)
1. Create PagerDuty integration key
2. Configure escalation policies
3. Set up on-call rotations

## 📝 Maintenance Tasks

### Daily
- [ ] Check dashboard for anomalies
- [ ] Review error rates and investigate spikes
- [ ] Monitor resource usage trends

### Weekly  
- [ ] Review alert effectiveness
- [ ] Update dashboard queries
- [ ] Check storage retention policies

### Monthly
- [ ] Analyze performance trends
- [ ] Update alerting thresholds
- [ ] Plan capacity scaling

## 🛠️ Troubleshooting

### Grafana Issues
```bash
# Check Grafana logs
kubectl logs -n monitoring deployment/grafana

# Restart Grafana
kubectl rollout restart deployment/grafana -n monitoring
```

### Prometheus Issues
```bash
# Check Prometheus logs
kubectl logs -n monitoring deployment/prometheus

# Check configuration
kubectl exec -n monitoring deployment/prometheus -- promtool check config /etc/prometheus/prometheus.yml
```

### No Data in Dashboards
1. Verify Prometheus data source connection
2. Check if targets are being scraped
3. Validate PromQL queries in Prometheus UI

## 📚 Additional Resources

- [Grafana Documentation](https://grafana.com/docs/)
- [Prometheus Query Language](https://prometheus.io/docs/prometheus/latest/querying/)
- [Kubernetes Monitoring Guide](https://kubernetes.io/docs/tasks/debug-application-cluster/resource-usage-monitoring/)
- [SRE Best Practices](https://sre.google/books/)

## 🎉 Success Criteria

Your monitoring is properly set up when you can:
- ✅ View real-time application metrics in Grafana
- ✅ Receive alerts for critical issues
- ✅ Track performance trends over time
- ✅ Quickly identify and resolve issues
- ✅ Make data-driven scaling decisions
