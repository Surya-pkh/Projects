#!/bin/bash

# Auto-Deploy Script for Trend App
# This script deploys the latest Docker image built by Jenkins to EKS

set -e

NAMESPACE="trend"
DEPLOYMENT="trend-app"
DOCKER_IMAGE="suryapkh/trend-app"

echo "🚀 Auto-Deploy Script for Trend App"
echo "======================================"

# Check if kubectl is configured
if ! kubectl cluster-info >/dev/null 2>&1; then
    echo "❌ kubectl is not configured or cluster not accessible"
    exit 1
fi

# Get the latest image tag from Docker Hub (optional - you can also specify manually)
echo "📦 Checking latest image..."
LATEST_TAG=$(curl -s "https://hub.docker.com/v2/repositories/${DOCKER_IMAGE}/tags/" | jq -r '.results[0].name' 2>/dev/null || echo "latest")
echo "Latest tag found: ${LATEST_TAG}"

# Allow manual override
if [ ! -z "$1" ]; then
    LATEST_TAG="$1"
    echo "Using manually specified tag: ${LATEST_TAG}"
fi

IMAGE_WITH_TAG="${DOCKER_IMAGE}:${LATEST_TAG}"

echo "🔄 Deploying ${IMAGE_WITH_TAG} to EKS..."

# Update the deployment
kubectl set image deployment/${DEPLOYMENT} ${DEPLOYMENT}=${IMAGE_WITH_TAG} -n ${NAMESPACE}

echo "⏳ Waiting for rollout to complete..."
kubectl rollout status deployment/${DEPLOYMENT} -n ${NAMESPACE} --timeout=300s

echo "✅ Deployment successful!"
echo ""
echo "📊 Current Status:"
kubectl get pods -n ${NAMESPACE}
echo ""
kubectl get svc -n ${NAMESPACE}

echo ""
echo "🔗 Application URL: http://a33f4d4d9655c4121a50242bb0a3942b-321113.us-west-2.elb.amazonaws.com"
echo "📊 Monitoring: http://34.210.247.74:3000"
echo ""
echo "🎉 Deployment complete!"
