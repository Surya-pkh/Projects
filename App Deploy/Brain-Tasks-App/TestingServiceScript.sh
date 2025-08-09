#!/bin/bash

# Step 1: Check LoadBalancer Service Status
echo "=== Checking LoadBalancer Service Status ==="
kubectl get svc brain-tasks-service -o wide
echo ""

# Step 2: Describe the service for detailed information
echo "=== Service Details ==="
kubectl describe svc brain-tasks-service
echo ""

# Step 3: Check if LoadBalancer has external IP assigned
echo "=== Waiting for External IP (this might take a few minutes) ==="
kubectl get svc brain-tasks-service --watch
# Press Ctrl+C once you see the EXTERNAL-IP assigned

echo ""
echo "=== Checking Pod Status ==="
kubectl get pods -l app=brain-tasks-app
echo ""

# Step 4: Check pod logs for any errors
echo "=== Checking Pod Logs ==="
POD_NAME=$(kubectl get pods -l app=brain-tasks-app -o jsonpath='{.items[0].metadata.name}')
kubectl logs $POD_NAME
echo ""

# Step 5: Test pod connectivity directly
echo "=== Testing Pod Port Forward ==="
echo "Run this command in a separate terminal to test direct pod access:"
echo "kubectl port-forward $POD_NAME 8080:3000"
echo "Then access http://localhost:8080"
echo ""

# Step 6: Check security groups and network ACLs
echo "=== Checking EKS Node Security Groups ==="
aws ec2 describe-security-groups --filters "Name=tag:aws:cloudformation:logical-id,Values=NodeSecurityGroup" --query 'SecurityGroups[*].{GroupId:GroupId,GroupName:GroupName,VpcId:VpcId}' --output table
echo ""

# Step 7: Check if the application is actually running on port 3000
echo "=== Checking if application is responding inside pod ==="
echo "Run this to exec into the pod and check:"
echo "kubectl exec -it $POD_NAME -- sh"
echo "Then inside the pod run: curl localhost:3000"