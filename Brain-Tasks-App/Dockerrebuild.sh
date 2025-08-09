#!/bin/bash

echo "=== Step 1: Create corrected Dockerfile ==="
cat > Dockerfile << 'EOF'
FROM nginx:alpine

# Remove default nginx static assets
RUN rm -rf /usr/share/nginx/html/*

# Copy your built files to nginx web root  
COPY dist /usr/share/nginx/html

# Remove default nginx configuration
RUN rm /etc/nginx/conf.d/default.conf

# Create custom nginx configuration for port 3000
RUN echo 'server { listen 3000; server_name localhost; root /usr/share/nginx/html; index index.html index.htm; location / { try_files $uri $uri/ /index.html; } }' > /etc/nginx/conf.d/default.conf

EXPOSE 3000

CMD ["nginx", "-g", "daemon off;"]
EOF

echo "=== Step 2: Rebuild Docker image ==="
docker build -t brain-tasks-app .

echo "=== Step 3: Test locally first ==="
echo "Testing the Docker image locally..."
docker run -d --name test-app -p 3001:3000 brain-tasks-app

# Wait a moment for nginx to start
sleep 5

echo "Testing local Docker container:"
curl -I http://localhost:3001

# Clean up test container
docker stop test-app && docker rm test-app

echo ""
echo "=== Step 4: Push to ECR ==="
ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text)

# Tag and push to ECR
docker tag brain-tasks-app:latest $ACCOUNT_ID.dkr.ecr.us-east-1.amazonaws.com/brain-tasks-app:latest
docker push $ACCOUNT_ID.dkr.ecr.us-east-1.amazonaws.com/brain-tasks-app:latest

echo ""
echo "=== Step 5: Restart Kubernetes deployment ==="
kubectl rollout restart deployment brain-tasks-app

echo "Waiting for rollout to complete..."
kubectl rollout status deployment brain-tasks-app

echo ""
echo "=== Step 6: Test the application ==="
echo "Waiting 30 seconds for pods to fully start..."
sleep 30

# Test the LoadBalancer
LB_URL="http://a2da7193a0514444e9013360f99a0e39-1665746955.us-east-1.elb.amazonaws.com"
echo "Testing LoadBalancer URL: $LB_URL"
curl -I $LB_URL

echo ""
echo "=== Final check ==="
kubectl get pods -l app=brain-tasks-app
echo ""
echo "Your application should now be accessible at:"
echo "$LB_URL"
echo ""
echo "You can also test it in browser by opening that URL."