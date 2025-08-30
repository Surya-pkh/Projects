# Trend Application Deployment Guide
#### Complete Setup Instructions with Screenshots

## Table of Contents
1. [Initial Setup](#1-initial-setup)
2. [Docker Configuration](#2-docker-configuration)
3. [AWS Setup](#3-aws-setup)
4. [Terraform Infrastructure](#4-terraform-infrastructure)
5. [Jenkins Configuration](#5-jenkins-configuration)
6. [Kubernetes Deployment](#6-kubernetes-deployment)
7. [Monitoring Setup](#7-monitoring-setup)
8. [Troubleshooting](#8-troubleshooting)

## 1. Initial Setup

### 1.1. Clone the Repository
```bash
git clone https://github.com/Vennilavan12/Trend.git
cd Trend
```
[Insert Screenshot: Successfully cloned repository]

### 1.2. Required Tools Installation
- AWS CLI
- Docker
- Terraform
- kubectl
- Git

[Insert Screenshot: Verify installations with version commands]
```bash
aws --version
docker --version
terraform --version
kubectl version
git --version
```

## 2. Docker Configuration

### 2.1. Create DockerHub Account
1. Go to https://hub.docker.com/
2. Create a new account or sign in
3. Create a new repository named "trend-app"

[Insert Screenshot: DockerHub repository creation]

### 2.2. Modify Dockerfile
Location: `/Trend/Dockerfile`

⚠️ **Important**: No modifications needed in the Dockerfile unless you want to change the Node.js version or nginx configuration.

### 2.3. Update DockerHub Credentials
In the Jenkinsfile, locate these lines and update:
```groovy
environment {
    DOCKER_IMAGE = 'your-dockerhub-username/trend-app'  // CHANGE THIS
    DOCKER_CREDENTIALS = 'docker-credentials-id'        // You'll set this in Jenkins
}
```

[Insert Screenshot: Jenkinsfile environment variables]

## 3. AWS Setup

### 3.1. AWS Credentials
1. Create an IAM user with necessary permissions
2. Save the Access Key and Secret Key

[Insert Screenshot: IAM user creation]

### 3.2. Configure AWS CLI
```bash
aws configure
```
Enter:
- AWS Access Key ID: [Your Access Key]
- AWS Secret Access Key: [Your Secret Key]
- Default region: us-west-2 (or your preferred region)
- Default output format: json

[Insert Screenshot: AWS CLI configuration]

## 4. Terraform Infrastructure

### 4.1. Update Terraform Variables
Location: `/terraform/variables.tf`

⚠️ **Important**: Update these values:
```hcl
variable "aws_region" {
  default = "us-west-2"  // Change to your preferred region
}

variable "key_name" {
  default = "your-key-pair-name"  // Change to your EC2 key pair name
}
```

[Insert Screenshot: Terraform variables file]

### 4.2. Initialize and Apply Terraform
```bash
cd terraform
terraform init
terraform plan
terraform apply
```

[Insert Screenshot: Successful terraform apply]

## 5. Jenkins Configuration

### 5.1. Access Jenkins
- URL: http://[JENKINS_EC2_IP]:8080
- Get initial admin password:
```bash
ssh ec2-user@[JENKINS_EC2_IP]
sudo cat /var/lib/jenkins/secrets/initialAdminPassword
```

[Insert Screenshot: Jenkins initial login]

### 5.2. Install Required Plugins
1. Docker Pipeline
2. Kubernetes CLI
3. Git
4. AWS

[Insert Screenshot: Jenkins plugins installation]

### 5.3. Configure Credentials
1. DockerHub:
   - Kind: Username with password
   - ID: docker-credentials-id
   - Username: [Your DockerHub username]
   - Password: [Your DockerHub password]

2. AWS:
   - Kind: AWS Credentials
   - ID: aws-credentials
   - Access Key ID: [Your AWS Access Key]
   - Secret Access Key: [Your AWS Secret Key]

3. Kubernetes:
   - Kind: Kubernetes configuration
   - ID: eks-config
   - Upload kubeconfig file from: ~/.kube/config

[Insert Screenshot: Jenkins credentials configuration]

### 5.4. Create Pipeline
1. New Item → Pipeline
2. Configure:
   - GitHub project: [Your GitHub repository URL]
   - Pipeline script from SCM
   - SCM: Git
   - Repository URL: [Your GitHub repository URL]
   - Branch: */main

[Insert Screenshot: Jenkins pipeline configuration]

### 5.5. Configure GitHub Webhook
1. Go to GitHub repository settings
2. Add webhook:
   - Payload URL: http://[JENKINS_EC2_IP]:8080/github-webhook/
   - Content type: application/json
   - Events: Just the push event

[Insert Screenshot: GitHub webhook configuration]

## 6. Kubernetes Deployment

### 6.1. Update Kubernetes Configuration
Location: `/kubernetes/deployment.yaml`

⚠️ **Important**: No manual changes needed; Jenkins will replace placeholders

### 6.2. Configure kubectl
```bash
aws eks update-kubeconfig --region us-west-2 --name trend-app-cluster
```

[Insert Screenshot: kubectl configuration]

### 6.3. Verify Deployment
```bash
kubectl get pods -n trend
kubectl get svc -n trend
```

[Insert Screenshot: Kubernetes resources status]

## 7. Monitoring Setup

### 7.1. Infrastructure Setup

#### 7.1.1. Update Terraform Variables
Location: `/terraform/monitoring_variables.tf`

⚠️ **Important**: Configure these variables:
```hcl
variable "monitoring_instance_type" {
  default = "t3.medium"  # Adjust based on your needs
}

variable "grafana_admin_password" {
  # Set a secure password
}
```

[Insert Screenshot: Terraform monitoring variables]

#### 7.1.2. Apply Monitoring Infrastructure
```bash
cd terraform
terraform apply
```

[Insert Screenshot: Successful monitoring infrastructure deployment]

### 7.2. Prometheus Configuration

#### 7.2.1. Verify Prometheus Deployment
```bash
kubectl get pods -n monitoring
kubectl get svc prometheus -n monitoring
```

[Insert Screenshot: Prometheus pods and service status]

#### 7.2.2. Access Prometheus Dashboard
- URL: http://[MONITORING_SERVER_IP]:9090
- Verify targets are up:
  1. Navigate to Status -> Targets
  2. Check all endpoints are "UP"

[Insert Screenshot: Prometheus targets page]

### 7.3. Grafana Setup

#### 7.3.1. Access Grafana
- URL: http://[MONITORING_SERVER_IP]:3000
- Default credentials:
  - Username: admin
  - Password: [Value set in grafana_admin_password]

[Insert Screenshot: Grafana login page]

#### 7.3.2. Available Dashboards

1. **Kubernetes Cluster Dashboard**
   - CPU Usage per Pod
   - Memory Usage per Pod
   - Node Status
   - Pod Status

[Insert Screenshot: Kubernetes dashboard]

2. **Application Dashboard**
   - HTTP Request Rate
   - Response Times
   - Error Rates
   - Resource Usage

[Insert Screenshot: Application dashboard]

### 7.4. Alert Configuration

#### 7.4.1. CPU Usage Alert
1. Navigate to Alerting -> Create Alert
2. Configure:
```yaml
Condition: avg(rate(container_cpu_usage_seconds_total{container!=""}[5m])) by (pod) > 0.8
Duration: 5m
```

[Insert Screenshot: CPU alert configuration]

#### 7.4.2. Memory Usage Alert
```yaml
Condition: sum(container_memory_usage_bytes{container!=""}) by (pod) > 1.5G
Duration: 5m
```

[Insert Screenshot: Memory alert configuration]

#### 7.4.3. Response Time Alert
```yaml
Condition: rate(http_request_duration_seconds_sum[5m]) / rate(http_request_duration_seconds_count[5m]) > 2
Duration: 5m
```

[Insert Screenshot: Response time alert configuration]

### 7.5. Monitoring Integration with Jenkins

The Jenkins pipeline automatically:
1. Deploys Prometheus and Grafana
2. Configures data sources
3. Imports dashboards
4. Sets up basic alerts

[Insert Screenshot: Jenkins monitoring deployment stage]

### 7.6. Custom Metrics

To add custom metrics to your React application:
1. Add Prometheus client library
2. Configure metrics:
```javascript
const httpRequestDuration = new promClient.Histogram({
  name: 'http_request_duration_seconds',
  help: 'Duration of HTTP requests in seconds',
  labelNames: ['method', 'route', 'status_code']
});
```

[Insert Screenshot: Custom metrics implementation]

### 7.7. Troubleshooting Monitoring

#### Common Issues

1. **Prometheus Target Down**
   ```bash
   kubectl logs -f deployment/prometheus -n monitoring
   kubectl describe pod [prometheus-pod-name] -n monitoring
   ```
   [Insert Screenshot: Prometheus logs]

2. **Grafana Can't Connect to Prometheus**
   - Verify Prometheus service is running
   - Check data source configuration
   ```bash
   kubectl get svc prometheus -n monitoring
   ```
   [Insert Screenshot: Prometheus service details]

3. **Missing Metrics**
   - Check scrape configuration
   - Verify pod annotations
   ```bash
   kubectl describe pod [pod-name] -n monitoring
   ```
   [Insert Screenshot: Pod annotations]

### 7.8. Monitoring Best Practices

1. **Resource Allocation**
   - Prometheus: Minimum 2GB RAM
   - Grafana: Minimum 1GB RAM
   - Configure retention periods based on storage

2. **Security**
   - Change default passwords
   - Use HTTPS for endpoints
   - Implement proper RBAC

3. **Backup**
   - Regular backup of Grafana dashboards
   - Prometheus data retention policy
   - Configuration backups

[Insert Screenshot: Monitoring resource configuration]

### 7.9. Monitoring Checklist

- [ ] Prometheus successfully scraping targets
- [ ] Grafana connected to Prometheus
- [ ] Dashboards showing data
- [ ] Alerts configured and tested
- [ ] Backup solution in place
- [ ] Security measures implemented
- [ ] Resource limits set appropriately
- [ ] Custom metrics configured

[Insert Screenshot: Monitoring checklist completion]

## 8. Troubleshooting

### 8.1. Common Issues and Solutions

#### Jenkins Pipeline Fails
1. Check Docker credentials
2. Verify AWS credentials
3. Check Kubernetes configuration

[Insert Screenshot: Jenkins error logs]

#### Kubernetes Deployment Issues
1. Check pod status:
```bash
kubectl describe pod [pod-name] -n trend
```
2. Check logs:
```bash
kubectl logs [pod-name] -n trend
```

[Insert Screenshot: Kubernetes troubleshooting]

#### Application Not Accessible
1. Check service status:
```bash
kubectl get svc trend-app-service -n trend
```
2. Verify security group settings

[Insert Screenshot: Service status and security groups]

## Final Verification Checklist

- [ ] Jenkins pipeline completes successfully
- [ ] Pods are running in Kubernetes
- [ ] Application accessible via Load Balancer
- [ ] Monitoring dashboards show data
- [ ] Auto-scaling working correctly
- [ ] Backups configured
- [ ] SSL/TLS configured (if applicable)

[Insert Screenshot: Final deployment status]

---

⚠️ **Remember to Never Commit**:
1. AWS credentials
2. DockerHub passwords
3. Private keys
4. Jenkins secrets
5. Kubeconfig files

Use environment variables or secure secret management tools instead.

[End of Document]
