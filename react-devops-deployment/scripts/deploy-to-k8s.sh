#!/bin/bash

# Deploy to Kubernetes Script

set -e

DOCKERHUB_USERNAME=${1:-"your-dockerhub-username"}
NAMESPACE="react-app"

echo "🚀 Deploying React application to Kubernetes..."

# Check if kubectl is configured
if ! kubectl cluster-info > /dev/null 2>&1; then
    echo "❌ kubectl is not configured or cluster is not accessible."
    echo "Run: aws eks update-kubeconfig --region us-west-2 --name react-app-cluster"
    exit 1
fi

# Update deployment with correct image
echo "📝 Updating deployment manifest..."
sed -i.bak "s|DOCKERHUB_USERNAME|$DOCKERHUB_USERNAME|g" kubernetes/deployment.yaml

# Apply Kubernetes manifests
echo "📋 Applying Kubernetes manifests..."
kubectl apply -f kubernetes/namespace.yaml
kubectl apply -f kubernetes/configmap.yaml
kubectl apply -f kubernetes/deployment.yaml
kubectl apply -f kubernetes/service.yaml

# Wait for deployment
echo "⏳ Waiting for deployment to complete..."
kubectl rollout status deployment/react-app-deployment -n $NAMESPACE --timeout=300s

# Get service information
echo "📊 Getting service information..."
kubectl get all -n $NAMESPACE

# Get LoadBalancer URL
echo "🌐 Getting LoadBalancer URL..."
LB_URL=$(kubectl get service react-app-service -n $NAMESPACE -o jsonpath='{.status.loadBalancer.ingress[0].hostname}')
if [ -n "$LB_URL" ]; then
    echo "✅ Application deployed successfully!"
    echo "🔗 LoadBalancer URL: http://$LB_URL"
else
    echo "⏳ LoadBalancer is still provisioning. Check again in a few minutes:"
    echo "kubectl get service react-app-service -n $NAMESPACE"
fi

# Restore original deployment file
mv kubernetes/deployment.yaml.bak kubernetes/deployment.yaml

echo "🎉 Deployment completed!"
