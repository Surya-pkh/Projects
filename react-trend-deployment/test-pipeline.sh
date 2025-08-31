#!/bin/bash

echo "🧪 Testing Jenkins Pipeline Setup"
echo "================================="

# Test 1: Check Jenkins accessibility
echo "1. Testing Jenkins accessibility..."
if curl -s http://54.68.35.10:8080 > /dev/null; then
    echo "✅ Jenkins is accessible"
else
    echo "❌ Jenkins is not accessible"
    exit 1
fi

# Test 2: Check EKS connectivity
echo "2. Testing EKS connectivity..."
if kubectl get nodes > /dev/null 2>&1; then
    echo "✅ EKS cluster is accessible"
    kubectl get nodes
else
    echo "❌ EKS cluster is not accessible"
fi

# Test 3: Check current application status
echo "3. Checking current application status..."
kubectl get pods -n trend
kubectl get svc -n trend

# Test 4: Check Docker Hub connectivity
echo "4. Testing Docker Hub connectivity..."
if docker search suryapkh/trend-app > /dev/null 2>&1; then
    echo "✅ Docker Hub is accessible"
else
    echo "❌ Docker Hub connectivity issue"
fi

# Test 5: Check application URL
echo "5. Testing application URL..."
APP_URL="http://a33f4d4d9655c4121a50242bb0a3942b-321113.us-west-2.elb.amazonaws.com"
if curl -s --max-time 10 $APP_URL > /dev/null; then
    echo "✅ Application is responding"
else
    echo "❌ Application is not responding"
fi

echo ""
echo "🎯 Manual Pipeline Test:"
echo "1. Go to Jenkins: http://54.68.35.10:8080"
echo "2. Click on your pipeline job"
echo "3. Click 'Build Now'"
echo "4. Monitor the build progress"
echo ""
echo "📊 Monitor deployment:"
echo "- Jenkins: http://54.68.35.10:8080"
echo "- Application: $APP_URL"
echo "- Grafana: http://34.210.247.74:3000"
echo ""
