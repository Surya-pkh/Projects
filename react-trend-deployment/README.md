# 🚀 Trend Application - Production Deployment Guide

# 🚀 Trend E-commerce Application - Production Deployment

A modern React-based e-commerce application (Trendify) deployed on AWS EKS with complete CI/CD pipeline and monitoring.

## 📋 Table of Contents

- [Overview](#overview)
- [Architecture](#architecture)
- [Prerequisites](#prerequisites)
- [Quick Start](#quick-start)
- [Manual Setup](#manual-setup)
- [CI/CD Pipeline](#cicd-pipeline)
- [Monitoring](#monitoring)
- [Troubleshooting](#troubleshooting)
- [Cleanup](#cleanup)

# Trend Application - Complete Production Deployment

A modern React e-commerce application with complete CI/CD pipeline and monitoring stack.

## 🚀 Features

- **React Frontend**: Modern e-commerce interface
- **Docker Container**: Production-ready containerization
- **Kubernetes Deployment**: Scalable container orchestration
- **CI/CD Pipeline**: Automated Jenkins pipeline
- **Monitoring Stack**: Prometheus & Grafana monitoring
- **AWS Infrastructure**: EKS cluster with auto-scaling

## 📋 Overview

**Trend Application** is a modern React e-commerce platform deployed on AWS EKS with full DevOps automation including:

## 🏗️ Architecture

```
┌─────────────────┐    ┌─────────────────┐    ┌─────────────────┐
│   Developer     │    │    Jenkins      │    │   DockerHub     │
│   Commits       │───▶│   CI/CD         │───▶│   Registry      │
└─────────────────┘    └─────────────────┘    └─────────────────┘
                                │
                                ▼
┌─────────────────────────────────────────────────────────────────┐
│                        AWS EKS Cluster                         │
│  ┌─────────────┐  ┌─────────────┐  ┌─────────────────────────┐  │
│  │   Trend     │  │   Trend     │  │     Load Balancer       │  │
│  │   Pod 1     │  │   Pod 2     │  │    (Public Access)      │  │
│  └─────────────┘  └─────────────┘  └─────────────────────────┘  │
└─────────────────────────────────────────────────────────────────┘
                                │
                                ▼
┌─────────────────────────────────────────────────────────────────┐
│                      Monitoring Stack                          │
│  ┌─────────────┐  ┌─────────────┐  ┌─────────────────────────┐  │
│  │ Prometheus  │  │   Grafana   │  │     CloudWatch          │  │
│  │ Metrics     │  │ Dashboard   │  │     Logs                │  │
│  └─────────────┘  └─────────────┘  └─────────────────────────┘  │
└─────────────────────────────────────────────────────────────────┘
```

## 🛠️ Prerequisites

### Required Tools
- **AWS CLI** (v2.x)
- **Docker** (v20.x+)
- **Terraform** (v1.5+)
- **kubectl** (v1.27+)
- **Git**
- **Node.js** (v18+) - for local development

### AWS Requirements
- AWS Account with appropriate permissions
- AWS CLI configured with credentials
- EC2 Key Pair for SSH access
- VPC with public/private subnets (created by Terraform)

### DockerHub Account
- Create account at [hub.docker.com](https://hub.docker.com)
- Create repository named `trend-app`

## ⚡ Quick Start

### 1. Clone and Setup
```bash
git clone https://github.com/Vennilavan12/Trend.git
cd react-trend-deployment
```

### 2. Configure Variables
Edit `terraform/variables.tf` and update:
```hcl
variable "key_name" {
  default = "your-ec2-key-pair-name"
}
```

Update `deploy.sh` and `Jenkinsfile` with your DockerHub username:
```bash
DOCKER_IMAGE="your-dockerhub-username/trend-app"
```

### 3. Deploy Everything
```bash
./deploy.sh all
```

### 4. Access Application
After deployment completes:
```bash
./deploy.sh status
```

## 📖 Manual Setup

### Step 1: Infrastructure Deployment

```bash
# Navigate to terraform directory
cd terraform

# Initialize Terraform
terraform init

# Plan deployment
terraform plan

# Apply configuration
terraform apply

# Note the outputs
terraform output
```

### Step 2: Docker Image Build

```bash
# Build Docker image
docker build -t your-dockerhub-username/trend-app:latest .

# Test locally
docker run -p 3000:3000 your-dockerhub-username/trend-app:latest

# Push to DockerHub
docker push your-dockerhub-username/trend-app:latest
```

### Step 3: Kubernetes Deployment

```bash
# Configure kubectl
aws eks update-kubeconfig --name trend-app-cluster --region us-west-2

# Deploy to Kubernetes
kubectl apply -f kubernetes/namespace.yaml
kubectl apply -f kubernetes/configmap.yaml
kubectl apply -f kubernetes/deployment.yaml
kubectl apply -f kubernetes/service.yaml
kubectl apply -f kubernetes/hpa.yaml

# Check deployment status
kubectl get pods -n trend
kubectl get services -n trend
```

## 🔄 CI/CD Pipeline

### Jenkins Setup

1. **Access Jenkins**
   ```bash
   # Get Jenkins URL from Terraform output
   terraform output jenkins_url
   
   # Get initial admin password
   ssh -i your-key.pem ubuntu@<jenkins-ip>
   sudo cat /var/lib/jenkins/secrets/initialAdminPassword
   ```

2. **Configure Credentials**
   - DockerHub credentials
   - AWS credentials
   - GitHub webhook token

3. **Create Pipeline**
   - New Item → Pipeline
   - Pipeline script from SCM
   - Repository URL: your GitHub repo
   - Script Path: Jenkinsfile

### Pipeline Stages

1. **Checkout** - Clone repository
2. **Lint & Test** - Code quality checks
3. **Security Scan** - Docker image vulnerability scan
4. **Build** - Build Docker image
5. **Test** - Test Docker image
6. **Push** - Push to DockerHub
7. **Deploy** - Deploy to Kubernetes
8. **Smoke Tests** - Verify deployment

## 📊 Monitoring

### Access Monitoring
```bash
# Get monitoring instance IP
terraform output monitoring_instance_ip

# Prometheus: http://<monitoring-ip>:9090
# Grafana: http://<monitoring-ip>:3000
# Credentials: admin / admin123
```

## 🔍 Troubleshooting

### Common Issues

#### 1. EKS Cluster Access Denied
```bash
# Update kubeconfig
aws eks update-kubeconfig --name trend-app-cluster --region us-west-2
```

#### 2. LoadBalancer Not Ready
```bash
# Check service status
kubectl describe service trend-app-service -n trend
```

### Application URL
After successful deployment, the application will be available at:
```
http://<LoadBalancer-DNS>/
```

## 🧹 Cleanup

```bash
# Destroy Kubernetes resources
kubectl delete namespace trend

# Destroy Terraform infrastructure
cd terraform
terraform destroy
```

## 📚 Features Implemented

✅ **Application Deployment**
- Cloned React application from GitHub
- Dockerized with nginx on port 3000
- Production-ready configuration

✅ **Infrastructure as Code**
- VPC with public/private subnets
- EKS cluster with worker nodes
- Jenkins EC2 instance with IAM roles
- Security groups and networking

✅ **Kubernetes Setup**
- Namespace isolation
- ConfigMaps for configuration
- Deployment with health checks
- LoadBalancer service
- Horizontal Pod Autoscaler
- Ingress configuration

✅ **CI/CD Pipeline**
- Complete Jenkins pipeline
- Docker build and push
- Automated K8s deployment
- Security scanning
- Smoke tests

✅ **Monitoring**
- Prometheus metrics collection
- Grafana dashboards
- Node exporter for system metrics
- Application health monitoring

✅ **Version Control**
- Comprehensive .gitignore
- .dockerignore for builds
- GitHub integration ready

✅ **Documentation**
- Complete setup guide
- Troubleshooting section
- Architecture diagrams
- Step-by-step instructions

## 🎯 LoadBalancer ARN

After deployment, get the LoadBalancer ARN with:
```bash
kubectl get service trend-app-service -n trend -o jsonpath='{.status.loadBalancer.ingress[0].hostname}'
```

The LoadBalancer ARN will be displayed in the Terraform outputs and can be found in the AWS console under EC2 → Load Balancers.

---

**🚀 Your Trend application is now production-ready with enterprise-grade infrastructure!**
