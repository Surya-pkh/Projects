# CI/CD Pipeline Documentation

## Pipeline Overview

This Jenkins pipeline automates the entire deployment process from code commit to production deployment on Kubernetes.

## Pipeline Stages

### 1. Checkout
- Retrieves source code from GitHub
- Triggered automatically via webhook on code push

### 2. Build Application
- Installs Node.js dependencies
- Builds React application for production
- Creates optimized build artifacts

### 3. Build Docker Image
- Creates Docker image with built application
- Tags with build number and 'latest'
- Uses multi-stage build for optimization

### 4. Run Tests
- Executes unit tests
- Runs security scans
- Validates code quality

### 5. Push to DockerHub
- Authenticates with DockerHub
- Pushes Docker images
- Updates both versioned and latest tags

### 6. Deploy to Kubernetes
- Updates Kubernetes manifests
- Applies changes to EKS cluster
- Waits for successful rollout

### 7. Health Check
- Verifies pod readiness
- Checks service endpoints
- Validates deployment status

## Pipeline Configuration

### Environment Variables
```groovy
DOCKERHUB_CREDENTIALS = credentials('dockerhub-credentials')
DOCKERHUB_USERNAME = 'your-dockerhub-username'
IMAGE_NAME = 'react-trend-app'
IMAGE_TAG = "${BUILD_NUMBER}"
KUBECONFIG_CREDENTIAL = credentials('kubeconfig')
AWS_DEFAULT_REGION = 'us-west-2'
```

### Required Credentials
1. `dockerhub-credentials` - DockerHub username/password
2. `kubeconfig` - Kubernetes configuration file
3. `github-token` - GitHub access token (for webhooks)

## Webhook Configuration

### GitHub Webhook Setup
1. Repository Settings → Webhooks
2. Payload URL: `http://<jenkins-ip>:8080/github-webhook/`
3. Content type: `application/json`
4. Events: Push events

### Jenkins Webhook Configuration
1. Install GitHub plugin
2. Configure GitHub server settings
3. Enable "GitHub hook trigger for GITScm polling"

## Monitoring and Notifications

### Build Notifications
- Success: Email notification sent
- Failure: Alert email with build logs
- Slack integration (optional)

### Pipeline Metrics
- Build duration tracking
- Success/failure rates
- Deployment frequency

## Best Practices

### Security
- Use Jenkins credentials for all secrets
- Scan images for vulnerabilities
- Validate Kubernetes manifests

### Performance
- Parallel stage execution where possible
- Docker layer caching
- Artifact management

### Reliability
- Rollback capabilities
- Health checks after deployment
- Automated testing at each stage

## Troubleshooting

### Common Pipeline Issues

1. **Docker Build Fails**
   ```bash
   # Check Dockerfile syntax
   # Verify base image availability
   # Check Docker daemon status
   ```

2. **Kubernetes Deploy Fails**
   ```bash
   # Verify kubeconfig
   kubectl config current-context
   
   # Check cluster connectivity
   kubectl cluster-info
   
   # Verify namespace exists
   kubectl get namespace react-app
   ```

3. **Image Push Fails**
   ```bash
   # Check DockerHub credentials
   # Verify repository exists
   # Check network connectivity
   ```

### Pipeline Debugging
```groovy
// Add debug steps in Jenkinsfile
sh 'env | sort'
sh 'docker images'
sh 'kubectl get pods -n react-app'
```

## Pipeline Customization

### Adding Stages
```groovy
stage('Static Code Analysis') {
    steps {
        sh 'npm run lint'
        sh 'npm audit'
    }
}

stage('Integration Tests') {
    steps {
        sh 'npm run test:integration'
    }
}
```

### Environment-specific Deployments
```groovy
stage('Deploy to Staging') {
    when {
        branch 'develop'
    }
    steps {
        // Staging deployment steps
    }
}

stage('Deploy to Production') {
    when {
        branch 'main'
    }
    steps {
        // Production deployment steps
    }
}
```

## Metrics and KPIs

### Deployment Metrics
- Deployment frequency
- Lead time for changes
- Mean time to recovery
- Change failure rate

### Quality Metrics
- Test coverage percentage
- Security vulnerability count
- Code quality scores

## Advanced Features

### Blue-Green Deployment
```yaml
# Kubernetes service selector update
spec:
  selector:
    app: react-app
    version: blue  # or green
```

### Canary Deployment
```yaml
# Weight-based traffic splitting
spec:
  replicas: 1  # Canary
  selector:
    matchLabels:
      app: react-app
      version: canary
```

### Rollback Strategy
```bash
# Rollback to previous version
kubectl rollout undo deployment/react-app-deployment -n react-app

# Rollback to specific revision
kubectl rollout undo deployment/react-app-deployment --to-revision=2 -n react-app
```
