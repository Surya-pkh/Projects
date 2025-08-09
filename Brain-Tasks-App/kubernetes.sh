#!/bin/bash
# Apply the deployment and service
kubectl apply -f k8s/deployment.yaml
kubectl apply -f k8s/service.yaml

# Check the status
kubectl get deployments
kubectl get services
kubectl get pods