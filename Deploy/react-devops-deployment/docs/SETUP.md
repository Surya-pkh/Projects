# Complete DevOps Setup Guide

This guide walks you through deploying a React application using Docker, Terraform, AWS EKS, Jenkins, and monitoring.

## Phase 1: Prerequisites and Initial Setup

### 1.1 Update Variables
Edit `terraform/variables.tf` and update:
```hcl
variable "dockerhub_username" {
  default = "your-actual-dockerhub-username"
}
```

### 1.2 Create AWS Key Pair
```bash
# Create key pair for EC2 instances
aws ec2 create-key-pair --key-name devops-key --query 'KeyMaterial' --output text > devops-key.pem
chmod 400 devops-key.pem
```

### 1.3 Verify Setup
```bash
./scripts/verify-setup.sh
```

## Phase 2: Infrastructure Deployment

### 2.1 Deploy Infrastructure with Terraform
```bash
cd terraform

# Initialize Terraform
terraform init

# Plan the deployment
terraform plan

# Apply the infrastructure
terraform apply
```

**Note**: This will create:
- VPC with public/private subnets
- EKS cluster with worker nodes
- Jenkins server (EC2)
- Monitoring server (EC2)
- Security groups and IAM roles

### 2.2 Configure kubectl
```bash
# Update kubeconfig for EKS
aws eks update-kubeconfig --region us-west-2 --name react-app-cluster

# Verify connection
kubectl get nodes
```

## Phase 3: Application Deployment

### 3.1 Build and Push Docker Image
```bash
# Make sure you have a DockerHub account
./scripts/build-and-push.sh your-dockerhub-username
```

### 3.2 Deploy to Kubernetes
```bash
./scripts/deploy-to-k8s.sh your-dockerhub-username
```

### 3.3 Get Application URL
```bash
kubectl get service react-app-service -n react-app
```

## Phase 4: Jenkins Setup

### 4.1 Access Jenkins Server
Get Jenkins server IP from Terraform output:
```bash
cd terraform
terraform output jenkins_url
```

### 4.2 Initial Jenkins Configuration
1. SSH to Jenkins server:
   ```bash
   ssh -i devops-key.pem ec2-user@<jenkins-ip>
   ```

2. Run Jenkins setup:
   ```bash
   sudo /opt/jenkins/jenkins-setup.sh
   ```

3. Access Jenkins web UI and complete setup:
   - Install suggested plugins
   - Create admin user
   - Install additional plugins from `jenkins/plugins.txt`

### 4.3 Configure Jenkins Credentials
Add these credentials in Jenkins:
1. **DockerHub credentials** (`dockerhub-credentials`)
2. **Kubeconfig file** (`kubeconfig`)
3. **GitHub token** (for webhooks)

### 4.4 Create Jenkins Pipeline
1. Create new Pipeline job
2. Configure GitHub repository
3. Use `jenkins/Jenkinsfile`
4. Enable GitHub webhook trigger

## Phase 5: Monitoring Setup

### 5.1 Access Monitoring Server
Get monitoring server IP:
```bash
cd terraform
terraform output prometheus_url
terraform output grafana_url
```

### 5.2 Setup Monitoring Stack
1. SSH to monitoring server:
   ```bash
   ssh -i devops-key.pem ec2-user@<monitoring-ip>
   ```

2. Run monitoring setup:
   ```bash
   sudo /opt/monitoring/monitoring-setup.sh
   ```

### 5.3 Access Monitoring Services
- **Prometheus**: http://\<monitoring-ip\>:9090
- **Grafana**: http://\<monitoring-ip\>:3000 (admin/admin123)

### 5.4 Configure Grafana
1. Login to Grafana (admin/admin123)
2. Import Kubernetes dashboard (ID: 7249)
3. Configure alerts and notification channels

## Phase 6: GitHub Integration

### 6.1 GitHub Webhook Configuration
1. Go to your GitHub repository settings
2. Add webhook: `http://<jenkins-ip>:8080/github-webhook/`
3. Select "application/json" and "Push events"

### 6.2 Test CI/CD Pipeline
1. Make changes to the React application
2. Commit and push to GitHub
3. Verify Jenkins pipeline triggers automatically
4. Check deployment in Kubernetes

## Phase 7: Verification and Testing

### 7.1 Verify Application
```bash
# Check pods status
kubectl get pods -n react-app

# Check service
kubectl get svc -n react-app

# Get LoadBalancer URL
kubectl get svc react-app-service -n react-app -o jsonpath='{.status.loadBalancer.ingress[0].hostname}'
```

### 7.2 Test Monitoring
1. Generate some load on the application
2. Check metrics in Prometheus
3. View dashboards in Grafana
4. Test alerting rules

## Troubleshooting

### Common Issues

1. **EKS cluster not accessible**
   ```bash
   aws eks update-kubeconfig --region us-west-2 --name react-app-cluster
   ```

2. **Jenkins can't connect to Kubernetes**
   - Check IAM roles and policies
   - Verify kubeconfig in Jenkins

3. **Application not accessible**
   - Check LoadBalancer provisioning: `kubectl get svc -n react-app`
   - Verify security groups allow traffic

4. **Monitoring not working**
   - Check Docker services: `docker-compose ps`
   - Verify security groups for ports 3000, 9090

### Useful Commands
```bash
# Get all resources
kubectl get all -n react-app

# Check logs
kubectl logs -f deployment/react-app-deployment -n react-app

# Restart deployment
kubectl rollout restart deployment/react-app-deployment -n react-app

# Scale application
kubectl scale deployment react-app-deployment --replicas=5 -n react-app
```

## Cleanup

To destroy all resources:
```bash
./scripts/cleanup.sh
```

## Security Considerations

1. **Network Security**
   - Use private subnets for worker nodes
   - Restrict security group rules
   - Enable VPC Flow Logs

2. **Access Control**
   - Use IAM roles with least privilege
   - Enable MFA for AWS accounts
   - Secure Jenkins with proper authentication

3. **Secrets Management**
   - Use Kubernetes secrets for sensitive data
   - Store credentials securely in Jenkins
   - Rotate access keys regularly

## Cost Optimization

1. **Right-sizing**
   - Monitor resource usage
   - Use appropriate instance types
   - Implement auto-scaling

2. **Resource Management**
   - Stop non-production environments
   - Use Spot instances for development
   - Monitor costs with AWS Cost Explorer

## Next Steps

1. **Advanced Features**
   - Implement GitOps with ArgoCD
   - Add service mesh (Istio)
   - Implement advanced monitoring

2. **Security Enhancements**
   - Add vulnerability scanning
   - Implement policy as code
   - Enable audit logging

3. **Performance Optimization**
   - Implement caching
   - Add CDN integration
   - Optimize container images
