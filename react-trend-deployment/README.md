# Trend Application Deployment

This repository contains the complete setup for deploying the Trend React application to AWS EKS using Jenkins CI/CD pipeline.

## Architecture Overview

The deployment architecture consists of:
- React application containerized with Docker
- AWS EKS cluster for Kubernetes orchestration
- Jenkins server for CI/CD pipeline
- Infrastructure as Code using Terraform
- Monitoring using Prometheus and Grafana

## Prerequisites

1. AWS Account with appropriate permissions
2. Docker Hub account
3. GitHub account
4. Domain name (optional)

## Setup Instructions

### 1. Infrastructure Setup

```bash
# Initialize Terraform
cd terraform
terraform init

# Review the plan
terraform plan

# Apply the infrastructure
terraform apply
```

### 2. Jenkins Setup

1. Access Jenkins at http://[JENKINS_IP]:8080
2. Install required plugins:
   - Docker Pipeline
   - Kubernetes CLI
   - Git
3. Configure credentials:
   - Docker Hub credentials
   - Kubernetes configuration
   - GitHub webhook

### 3. Kubernetes Setup

```bash
# Configure kubectl
aws eks update-kubeconfig --region us-west-2 --name trend-app-cluster

# Create namespace
kubectl apply -f kubernetes/namespace.yaml

# Deploy application
kubectl apply -f kubernetes/deployment.yaml
kubectl apply -f kubernetes/service.yaml
```

### 4. Application Deployment

1. Push code changes to GitHub
2. Jenkins will automatically:
   - Build Docker image
   - Push to Docker Hub
   - Deploy to Kubernetes

### 5. Monitoring Setup

1. Install Prometheus:
```bash
helm repo add prometheus-community https://prometheus-community.github.io/helm-charts
helm repo update
helm install prometheus prometheus-community/kube-prometheus-stack
```

2. Access Grafana:
```bash
kubectl port-forward svc/prometheus-grafana 3000:80
```

## CI/CD Pipeline

The Jenkins pipeline consists of the following stages:
1. Checkout code
2. Build Docker image
3. Push to Docker Hub
4. Deploy to Kubernetes

## Monitoring

The application is monitored using:
- Prometheus for metrics collection
- Grafana for visualization
- Custom dashboards for:
  - Application metrics
  - Kubernetes cluster health
  - Node metrics

## Load Balancer Access

The application can be accessed through the AWS Load Balancer:
```bash
kubectl get svc trend-app-service -n trend
```

## Security Considerations

1. All credentials are stored securely in Jenkins
2. Network access is restricted through Security Groups
3. Kubernetes RBAC is properly configured
4. Container security best practices are implemented

## Maintenance

1. Regular updates:
```bash
# Update Kubernetes deployments
kubectl apply -f kubernetes/

# Update infrastructure
terraform apply
```

2. Monitoring alerts are configured for:
   - High CPU/Memory usage
   - Application errors
   - Kubernetes node issues

## Troubleshooting

1. Check application logs:
```bash
kubectl logs -f deployment/trend-app -n trend
```

2. Check pod status:
```bash
kubectl get pods -n trend
```

3. Jenkins build logs are available in the Jenkins dashboard
