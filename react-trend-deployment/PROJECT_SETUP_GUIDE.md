# React Trend Application - Complete Setup & Deployment Guide

## Table of Contents
1. [Project Overview](#project-overview)
2. [Prerequisites](#prerequisites)
3. [Initial Setup](#initial-setup)
4. [Infrastructure Deployment](#infrastructure-deployment)
5. [Application Deployment](#application-deployment)
6. [Monitoring Setup](#monitoring-setup)
7. [CI/CD Pipeline](#cicd-pipeline)
8. [Troubleshooting](#troubleshooting)
9. [Future Enhancements](#future-enhancements)
10. [Maintenance Guide](#maintenance-guide)

---

## Project Overview

### Architecture
This project implements a production-ready React e-commerce application (Trendify) with:
- **Frontend**: React application served via nginx
- **Infrastructure**: AWS EKS cluster with auto-scaling
- **CI/CD**: Jenkins pipeline with automated deployments
- **Monitoring**: Prometheus + Grafana stack
- **Container Registry**: Docker Hub
- **Source Control**: GitHub

### Key URLs
- **Application**: `http://a33f4d4d9655c4121a50242bb0a3942b-321113.us-west-2.elb.amazonaws.com`
- **Jenkins**: `http://54.68.35.10:8080`
- **Grafana**: `http://aa29945fe1c614be5ae0b521f91e2e87-1553642504.us-west-2.elb.amazonaws.com:3000`
- **GitHub Repository**: `https://github.com/Surya-pkh/Projects/tree/main/react-trend-deployment`

---

## Prerequisites

### Required Tools
1. **AWS CLI v2** - Configure with appropriate permissions
2. **kubectl** - Kubernetes command-line tool
3. **terraform** - Infrastructure as Code tool
4. **docker** - Container platform
5. **git** - Version control

### AWS Prerequisites
- AWS Account with sufficient permissions
- EC2 Key Pair created (`devops-key` in our case)
- AWS CLI configured with access keys

### Docker Hub Account
- Account created at hub.docker.com
- Username: `suryapkh` (update as needed)

---

## Initial Setup

### 1. Clone Repository
```bash
git clone https://github.com/Surya-pkh/Projects.git
cd Projects/react-trend-deployment
```

### 2. Configure Variables
Copy and edit the terraform variables:
```bash
cp terraform.tfvars.example terraform.tfvars
# Edit terraform.tfvars with your specific values:
# - project_name
# - key_name (your EC2 key pair)
# - region
# - environment
```

### 3. Verify Prerequisites
```bash
# Check AWS CLI
aws sts get-caller-identity

# Check kubectl
kubectl version --client

# Check terraform
terraform version

# Check docker
docker version
```

---

## Infrastructure Deployment

### Phase 1: Deploy Core Infrastructure
```bash
cd terraform/
terraform init
terraform plan -var-file="../terraform.tfvars"
terraform apply -var-file="../terraform.tfvars"
```

**Expected Resources Created:**
- VPC with public/private subnets
- EKS cluster (`trend-app-cluster`)
- Jenkins EC2 instance
- Security groups and IAM roles
- Auto-scaling groups

### Phase 2: Configure kubectl
```bash
# Update kubeconfig
aws eks update-kubeconfig --region us-west-2 --name trend-app-cluster

# Verify cluster access
kubectl get nodes
```

### Phase 3: Create Namespaces
```bash
kubectl apply -f kubernetes/namespace.yaml
```

---

## Application Deployment

### Method 1: Manual Deployment
```bash
# Build and push Docker image
docker build -t suryapkh/trend-app:latest .
docker push suryapkh/trend-app:latest

# Deploy to Kubernetes
kubectl apply -f kubernetes/
```

### Method 2: Using Jenkins Pipeline (Recommended)
1. Access Jenkins at the provided URL
2. Configure credentials:
   - Docker Hub credentials
   - AWS credentials
3. Create pipeline from GitHub repository
4. Trigger build

### Verify Deployment
```bash
# Check pods
kubectl get pods -n trend

# Check services
kubectl get svc -n trend

# Check application health
curl http://<LOAD_BALANCER_URL>/health
```

---

## Monitoring Setup

### 1. Deploy Prometheus & Grafana
```bash
kubectl apply -f monitoring/
```

### 2. Configure RBAC for Prometheus
```bash
kubectl apply -f monitoring/prometheus-rbac.yaml
```

### 3. Access Grafana
- URL: `http://aa29945fe1c614be5ae0b521f91e2e87-1553642504.us-west-2.elb.amazonaws.com:3000`
- Default credentials: `admin/admin`

### 4. Import Dashboards
1. Login to Grafana
2. Navigate to Dashboards → Import
3. Upload `monitoring/grafana-dashboard-v1.json` or `monitoring/grafana-dashboard-v2.json`

### 5. Verify Metrics Collection
```bash
# Port-forward to Prometheus
kubectl port-forward service/prometheus 9090:9090 -n monitoring

# Check targets at http://localhost:9090/targets
# Verify trend-app targets are "UP"
```

---

## CI/CD Pipeline

### Jenkins Setup
The Jenkins instance is automatically configured with:
- Docker plugin
- Kubernetes plugin
- AWS CLI
- kubectl

### Pipeline Configuration
1. **Source**: GitHub repository with webhook integration
2. **Build**: React application build using npm
3. **Containerize**: Docker image creation and push to Docker Hub
4. **Deploy**: Kubernetes deployment via kubectl
5. **Verify**: Health checks and rollout verification

### Pipeline Stages
```groovy
stages {
    stage('Checkout') { ... }
    stage('Build React App') { ... }
    stage('Build Docker Image') { ... }
    stage('Push to Docker Hub') { ... }
    stage('Deploy to EKS') { ... }
    stage('Verify Deployment') { ... }
}
```

### Triggering Deployments
- **Automatic**: Push to main branch triggers build
- **Manual**: Trigger from Jenkins UI
- **Rollback**: Use previous Docker image tags

---

## Troubleshooting

### Common Issues

#### 1. EKS Access Issues
```bash
# Update kubeconfig
aws eks update-kubeconfig --region us-west-2 --name trend-app-cluster

# Check cluster status
kubectl cluster-info
```

#### 2. Jenkins Pipeline Failures
- Check Jenkins logs in the build console
- Verify AWS credentials are configured
- Ensure Docker Hub credentials are valid

#### 3. Prometheus Not Scraping Metrics
```bash
# Check Prometheus configuration
kubectl get configmap prometheus-config -n monitoring -o yaml

# Verify target discovery
kubectl port-forward service/prometheus 9090:9090 -n monitoring
# Visit http://localhost:9090/targets
```

#### 4. Application Health Issues
```bash
# Check pod logs
kubectl logs -n trend deployment/trend-app

# Check service endpoints
kubectl get endpoints -n trend

# Verify nginx configuration
kubectl exec -n trend deployment/trend-app -- nginx -t
```

### Log Locations
- **Application Logs**: `kubectl logs -n trend deployment/trend-app`
- **Jenkins Logs**: Available in Jenkins UI
- **Prometheus Logs**: `kubectl logs -n monitoring deployment/prometheus`
- **Grafana Logs**: `kubectl logs -n monitoring deployment/grafana`

---

## Future Enhancements

### Security Improvements
1. **SSL/TLS Termination**
   - Configure AWS Certificate Manager
   - Update ingress for HTTPS

2. **Network Policies**
   - Implement Kubernetes network policies
   - Restrict inter-pod communication

3. **Secret Management**
   - Use AWS Secrets Manager
   - Implement secret rotation

### Scalability Enhancements
1. **Database Integration**
   - Add PostgreSQL/MongoDB
   - Implement data persistence

2. **Caching Layer**
   - Add Redis for session management
   - Implement CDN for static assets

3. **Multi-Region Deployment**
   - Set up cross-region replication
   - Implement global load balancing

### Monitoring Enhancements
1. **Advanced Metrics**
   - Application performance monitoring
   - User experience metrics

2. **Alerting**
   - Configure Prometheus AlertManager
   - Set up PagerDuty/Slack notifications

3. **Log Aggregation**
   - Implement ELK stack
   - Centralized log management

### CI/CD Improvements
1. **Testing Integration**
   - Unit tests in pipeline
   - Integration testing
   - Security scanning

2. **Blue/Green Deployments**
   - Zero-downtime deployments
   - Automated rollback capabilities

3. **Multi-Environment Support**
   - Development/Staging/Production
   - Environment-specific configurations

---

## Maintenance Guide

### Daily Tasks
- Monitor application health via Grafana dashboards
- Check Jenkins build status
- Review application logs for errors

### Weekly Tasks
- Update Docker images with security patches
- Review resource utilization
- Backup terraform state files

### Monthly Tasks
- Update Kubernetes cluster version
- Review and update monitoring rules
- Security audit and access review

### Quarterly Tasks
- Infrastructure cost optimization
- Performance testing and optimization
- Documentation updates

### Emergency Procedures

#### Application Downtime
1. Check load balancer health
2. Verify pod status: `kubectl get pods -n trend`
3. Check recent deployments: `kubectl rollout history deployment/trend-app -n trend`
4. Rollback if needed: `kubectl rollout undo deployment/trend-app -n trend`

#### Infrastructure Issues
1. Check AWS service health dashboard
2. Verify EKS cluster status
3. Check node health: `kubectl get nodes`
4. Scale up if needed: `kubectl scale deployment trend-app --replicas=5 -n trend`

#### Data Loss Prevention
- Terraform state is stored locally - backup regularly
- Docker images are in Docker Hub registry
- Code is version controlled in GitHub

---

## Contact Information

### Key Personnel
- **DevOps Engineer**: [Your Name]
- **Project Manager**: [PM Name]
- **Development Team**: [Team Contacts]

### Support Escalation
1. **Level 1**: Application team
2. **Level 2**: DevOps team
3. **Level 3**: AWS support (if needed)

### Documentation Updates
This document should be updated whenever:
- Infrastructure changes are made
- New features are deployed
- Monitoring configurations change
- Security procedures are updated

---

## Appendix

### File Structure
```
react-trend-deployment/
├── Dockerfile                 # Container definition
├── Jenkinsfile               # CI/CD pipeline
├── nginx.conf                # Web server configuration
├── kubernetes/               # Kubernetes manifests
├── monitoring/               # Monitoring configurations
├── terraform/                # Infrastructure as Code
└── assets/                   # Built React application
```

### Key Commands Reference
```bash
# Kubernetes
kubectl get pods -n trend
kubectl logs -n trend deployment/trend-app
kubectl scale deployment trend-app --replicas=3 -n trend

# Docker
docker build -t suryapkh/trend-app:latest .
docker push suryapkh/trend-app:latest

# Terraform
terraform plan -var-file="../terraform.tfvars"
terraform apply -var-file="../terraform.tfvars"

# Monitoring
kubectl port-forward service/grafana 3000:3000 -n monitoring
kubectl port-forward service/prometheus 9090:9090 -n monitoring
```

### Resource Requirements
- **Minimum**: 2 vCPUs, 4GB RAM per worker node
- **Recommended**: 4 vCPUs, 8GB RAM per worker node
- **Storage**: 20GB per node for container images

---

*Document Version: 1.0*  
*Last Updated: August 31, 2025*  
*Next Review Date: September 30, 2025*
