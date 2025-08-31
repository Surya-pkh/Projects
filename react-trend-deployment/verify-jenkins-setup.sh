#!/bin/bash

echo "🔧 Jenkins Pipeline Setup Verification"
echo "====================================="
echo ""

# Test 1: Jenkins Accessibility
echo "1. Testing Jenkins accessibility..."
if curl -s -u admin:admin123 http://54.68.35.10:8080/api/json > /dev/null; then
    echo "✅ Jenkins is accessible with credentials"
else
    echo "❌ Jenkins access failed"
fi

# Test 2: Check GitHub Repository
echo ""
echo "2. Checking GitHub repository..."
if curl -s https://api.github.com/repos/Surya-pkh/Projects/contents/react-trend-deployment/Jenkinsfile > /dev/null; then
    echo "✅ Jenkinsfile found in repository"
    echo "   📂 Path: react-trend-deployment/Jenkinsfile"
else
    echo "❌ Jenkinsfile not found in repository"
fi

# Test 3: Check Docker Hub connectivity
echo ""
echo "3. Testing Docker Hub connectivity..."
if docker search suryapkh/trend-app > /dev/null 2>&1; then
    echo "✅ Docker Hub is accessible"
else
    echo "❌ Docker Hub connectivity issue"
fi

# Test 4: Check EKS cluster
echo ""
echo "4. Checking EKS cluster status..."
if kubectl get nodes > /dev/null 2>&1; then
    echo "✅ EKS cluster is accessible"
    echo "   Nodes:"
    kubectl get nodes --no-headers | awk '{print "   - " $1 " (" $2 ")"}'
else
    echo "❌ EKS cluster not accessible"
fi

# Test 5: Check current application
echo ""
echo "5. Checking current application status..."
kubectl get pods -n trend --no-headers 2>/dev/null | head -3 | awk '{print "   Pod: " $1 " - " $3}'

echo ""
echo "📋 Jenkins Pipeline Configuration Summary:"
echo "=========================================="
echo "Repository URL: https://github.com/Surya-pkh/Projects.git"
echo "Script Path: react-trend-deployment/Jenkinsfile"
echo "Jenkins URL: http://54.68.35.10:8080"
echo "Credentials needed: aws-credentials, docker-hub-credentials"
echo ""
echo "📝 Next Steps:"
echo "1. Configure credentials in Jenkins"
echo "2. Create pipeline job with above settings"
echo "3. Run initial build to test"
echo "4. Monitor deployment in Kubernetes"
echo ""
echo "🎯 Expected Pipeline Flow:"
echo "Checkout → Build Docker → Push to Hub → Deploy to EKS → Health Check"
echo ""
